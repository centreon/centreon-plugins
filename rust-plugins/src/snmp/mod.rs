//! SNMP protocol communication using SNMPv2c bulk get/walk operations.
//!
//! Provides functions to query SNMP agents via UDP, parse responses,
//! and store results as vectors or scalars for metric computation.

extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;

use crate::compute::ast::ExprResult;
use crate::generic::error::Error::EmptyResponse;
use crate::generic::error::Error::FailedToConnectToHost;
use crate::generic::error::Error::InvalidSnmpPduDecode;
use crate::generic::error::Error::InvalidSnmpPduEncode;
use crate::generic::error::Error::InvalidSnmpValue;
use log::info;
use log::{trace, warn};
use rasn::types::ObjectIdentifier;
use rasn_smi::v2::{ApplicationSyntax, ObjectSyntax, SimpleSyntax};
use rasn_snmp::v2::BulkPdu;
use rasn_snmp::v2::GetBulkRequest;
use rasn_snmp::v2::Pdus;
use rasn_snmp::v2::VarBind;
use rasn_snmp::v2::VarBindValue;
use rasn_snmp::v2c::Message;
use rasn_snmp::v3::VarBindValue::EndOfMibView;
use std::collections::HashMap;
use std::convert::TryInto;
use std::net::UdpSocket;

/// The SNMP value type decoded from a single OID's response.
#[derive(Debug, Clone)]
pub enum ValueType {
    /// A 64-bit signed integer (covers INTEGER, TimeTicks, Gauge32/Unsigned32).
    Integer(i64),
    /// A textual value (OCTET STRING, OBJECT IDENTIFIER, IpAddress, Opaque).
    String(String),
    /// A 64-bit unsigned counter (Counter32, Counter64).
    Counter64(u64),
}

impl ValueType {
    /// Converts this value to a float for storage in a numeric [`ExprResult`].
    ///
    /// # Panics
    /// Panics if called on a [`ValueType::String`]; callers must only reach
    /// this path for OIDs whose previously stored values were numeric.
    fn as_f64(&self) -> f64 {
        match self {
            ValueType::Integer(i) => *i as f64,
            ValueType::Counter64(i) => *i as f64,
            ValueType::String(_) => panic!("Expected a numeric SNMP value, got a string"),
        }
    }
}

/// Decodes a single varbind's value into a [`ValueType`].
///
/// Returns `Ok(None)` for markers that carry no data (unset value, no such
/// object/instance, or end of MIB view) since these are legitimate responses
/// an SNMP agent can send, not decode failures.
fn value_from_varbind(value: &VarBindValue) -> Result<Option<ValueType>> {
    let value = match value {
        VarBindValue::Unspecified => {
            warn!("SNMP varbind value is Unspecified");
            return Ok(None);
        }
        VarBindValue::NoSuchObject => {
            warn!("SNMP varbind value is NoSuchObject");
            return Ok(None);
        }
        VarBindValue::NoSuchInstance => {
            warn!("SNMP varbind value is NoSuchInstance");
            return Ok(None);
        }
        VarBindValue::EndOfMibView => {
            warn!("SNMP varbind value is EndOfMibView");
            return Ok(None);
        }
        VarBindValue::Value(value) => value,
    };

    let typ = match value {
        ObjectSyntax::Simple(simple) => match simple {
            SimpleSyntax::Integer(i) => {
                ValueType::Integer(i.try_into().map_err(|e| InvalidSnmpValue {
                    detail: format!("integer value '{}' does not fit in 64 bits: {}", i, e),
                })?)
            }
            // SNMP OCTET STRINGs are not guaranteed to be valid UTF-8 (e.g. MAC
            // addresses), so lossily converting avoids failing the whole request.
            SimpleSyntax::String(s) => ValueType::String(String::from_utf8_lossy(s).into_owned()),
            SimpleSyntax::ObjectId(oid) => {
                ValueType::String(oid.iter().map(u32::to_string).collect::<Vec<_>>().join("."))
            }
        },
        ObjectSyntax::ApplicationWide(app) => match app {
            ApplicationSyntax::Address(ip) => {
                let bytes = &*ip.0;
                ValueType::String(format!(
                    "{}.{}.{}.{}",
                    bytes[0], bytes[1], bytes[2], bytes[3]
                ))
            }
            ApplicationSyntax::Counter(counter) => ValueType::Counter64(counter.0.into()),
            ApplicationSyntax::Ticks(time_ticks) => ValueType::Integer(time_ticks.0.into()),
            ApplicationSyntax::Arbitrary(opaque) => ValueType::String(
                opaque
                    .as_ref()
                    .iter()
                    .map(|b| format!("{:02x}", b))
                    .collect(),
            ),
            ApplicationSyntax::BigCounter(counter64) => ValueType::Counter64(counter64.0),
            ApplicationSyntax::Unsigned(gauge) => ValueType::Counter64(gauge.0.into()),
        },
    };
    Ok(Some(typ))
}

/// Result of an SNMP query operation.
///
/// Stores collected values keyed by OID name, and tracks the last OID
/// for walk-based operations.
#[derive(Debug)]
pub struct SnmpResult {
    /// Collected values from this SNMP query, indexed by OID name.
    pub items: HashMap<String, ExprResult>,
    last_oid: Vec<u32>,
}

impl SnmpResult {
    /// Creates a new `SnmpResult` with the given items map.
    pub fn new(items: HashMap<String, ExprResult>) -> SnmpResult {
        SnmpResult {
            items,
            last_oid: Vec::new(),
        }
    }
}

/// Helper function to parse a numerical oid and return a vector containing the list of id composing the oid.
///
/// # Arguments
/// * `oid` - string in the form '.1.3.6.1.2', the first dot being optionnal.
///
/// # Returns
/// an array of unsigned number representing the oid, or an error if one of the oid part was not a number
///
pub fn oid_to_vec(oid: &str) -> Result<Vec<u32>> {
    let mut oid_u32: Vec<u32> = vec![];
    for id in oid.split('.').skip_while(|d| d.is_empty()) {
        // OIDs are generally given starting with a '.' so the first digit may be empty
        oid_u32.push(id.parse::<u32>().map_err(|_| InvalidOidParser {
            oid: oid.to_string(),
        })?);
    }
    return Ok(oid_u32);
}

/// Create an udp socket and send a snmp request on it, returning the response.
/// This function is blocking.
///
/// # Arguments
/// * `target` - Target address in "host:port" format
/// * `message` - Snmp Message, containing the snmp version, comunity, and a Pdu
///
/// # Returns
/// A Message<Pdu> containing the answers from the target, or an error if it was not reacheable/decodable
///
// This cfg allow to replace the function in the unit tests at the end of the file
#[cfg(test)]
fn get_data_from_udp(target: &str, message: Message<GetBulkRequest>) -> Result<Message<Pdus>> {
    Err(InvalidSnmpPduEncode {})
}
#[cfg(not(test))]
pub fn get_data_from_udp(target: &str, message: Message<GetBulkRequest>) -> Result<Message<Pdus>> {
    let socket = UdpSocket::bind("0.0.0.0:0")?;
    socket.connect(target)?;
    let duration = std::time::Duration::from_millis(1000);
    socket.set_read_timeout(Some(duration))?;
    // Send the message through an UDP socket
    let encoded: Vec<u8> = rasn::der::encode(&message).map_err(|_| InvalidSnmpPduEncode {})?;
    let res: usize = socket.send(&encoded)?;
    assert!(res == encoded.len());
    let mut buf: [u8; 1024] = [0; 1024];
    info!("waiting to receive data from {:?}", socket.peer_addr());
    let resp: (usize, std::net::SocketAddr) =
        socket
            .recv_from(buf.as_mut_slice())
            .map_err(|e| FailedToConnectToHost {
                url: target.to_string(),
                os: e.to_string(),
            })?;

    info!("Received {} bytes", resp.0);
    if resp.0 == 0 {
        return Err(EmptyResponse {});
    }

    let resp =
        rasn::ber::decode(&buf[0..resp.0]).map_err(|e| InvalidSnmpPduDecode { err: e.to_string() });
    trace!("Received an snmp answer : {:?}", resp);
    resp
}

/// Retrieves values for multiple OIDs in a single bulk request.
///
/// # Arguments
/// * `target` - Target address in "host:port" format
/// * `_version` - SNMP version (e.g., "2c")
/// * `community` - SNMP community string
/// * `non_repeaters` - Number of non-repeating OIDs (typically 0 or 1)
/// * `max_repetitions` - Maximum repetitions per OID
/// * `oid` - Vector of OID strings to query
/// * `names` - Vector of logical names (one per OID)
///
/// # Returns
/// An Result<[`SnmpResult`]> containing the retrieved values indexed by name, or an error
///
use crate::Error::InvalidOidParser;
use crate::generic::error::Result;
pub fn snmp_bulk_get<'a>(
    target: &str,
    _version: &str,
    community: &str,
    non_repeaters: u32,
    max_repetitions: u32,
    oid_list: &Vec<&str>,
    names: &Vec<&str>,
) -> Result<SnmpResult> {
    let mut oids_tab: Vec<Vec<u32>> = vec![];
    for oid_str in oid_list {
        let mut oid = oid_to_vec(oid_str)?;
        // As we only use bulk requests, we have to skip the trailing 0 if it exists or the first OID we are trying to get will never be requested
        let _ = oid.pop_if(|val| *val == 0);
        oids_tab.push(oid);
    }

    let mut retval = SnmpResult {
        items: HashMap::new(),
        last_oid: Vec::new(),
    };
    let request_id: i32 = 1;

    let variable_bindings = oids_tab
        .iter()
        .map(|x| VarBind {
            name: ObjectIdentifier::new_unchecked(x.to_vec().into()),
            value: VarBindValue::Unspecified,
        })
        .collect::<Vec<VarBind>>();

    let pdu = BulkPdu {
        request_id,
        variable_bindings,
        non_repeaters,
        max_repetitions,
    };

    let get_request: GetBulkRequest = GetBulkRequest(pdu);

    let message: Message<GetBulkRequest> = Message {
        version: 1.into(),
        community: community.to_string().into(),
        data: get_request.into(),
    };
    let decoded = get_data_from_udp(target, message)?;

    let _completed = retval.build_response_with_names(decoded, "", names, false)?;
    Ok(retval)
}

/// Walks a subtree of OIDs using repeated bulk requests until the subtree is exhausted.
///
/// Continues retrieving values until an OID outside the subtree is encountered
/// or a timeout occurs.
///
/// # Arguments
/// * `target` - Target address in "host:port" format
/// * `_version` - SNMP version (e.g., "2c")
/// * `community` - SNMP community string
/// * `oid` - The base OID to walk
/// * `snmp_name` - Logical name for collected values
///
/// # Returns
/// An [`SnmpResult`] containing all values under the specified OID
pub fn snmp_bulk_walk<'a>(
    target: &str,
    _version: &str,
    community: &str,
    oid: &str,
    snmp_name: &str,
) -> Result<SnmpResult> {
    let oid_init = oid_to_vec(oid)?;
    let mut oid_tab = &oid_init;
    let mut retval = SnmpResult {
        items: HashMap::new(),
        last_oid: Vec::new(),
    };
    let request_id: i32 = 1;
    loop {
        let variable_bindings = vec![VarBind {
            name: ObjectIdentifier::new_unchecked(oid_tab.to_vec().into()),
            value: VarBindValue::Unspecified,
        }];

        let pdu = BulkPdu {
            request_id,
            non_repeaters: 0,
            max_repetitions: 10,
            variable_bindings,
        };

        let get_request: GetBulkRequest = GetBulkRequest(pdu);

        let message: Message<GetBulkRequest> = Message {
            version: 1.into(),
            community: community.to_string().into(),
            data: get_request.into(),
        };

        let decoded = get_data_from_udp(target, message)?;
        let completed = retval.build_response(decoded, &oid, snmp_name, true)?;

        if completed {
            break;
        }
        oid_tab = &retval.last_oid;
    }
    Ok(retval)
}

/// Walks a subtree and organizes results by label matches.
///
/// Used for tabular SNMP data where the last segment of an OID identifies
/// the column (labeled in the `labels` map), and values are organized per label.
///
/// # Arguments
/// * `target` - Target address in "host:port" format
/// * `_version` - SNMP version (e.g., "2c")
/// * `community` - SNMP community string
/// * `oid` - The base OID to walk
/// * `snmp_name` - Logical name prefix for collected values
/// * `labels` - Map of label identifiers to logical names
///
/// # Returns
/// An [`SnmpResult`] with values organized by label as separate vectors
pub fn snmp_bulk_walk_with_labels<'a>(
    target: &str,
    _version: &str,
    community: &str,
    oid: &str,
    snmp_name: &str,
    labels: &'a HashMap<String, String>,
) -> Result<SnmpResult> {
    let oid_init = oid_to_vec(oid)?;
    let mut oid_tab = &oid_init;
    let mut retval = SnmpResult {
        items: HashMap::new(),
        last_oid: Vec::new(),
    };
    let request_id: i32 = 1;

    loop {
        let variable_bindings = vec![VarBind {
            name: ObjectIdentifier::new_unchecked(oid_tab.to_vec().into()),
            value: VarBindValue::Unspecified,
        }];

        let pdu = BulkPdu {
            request_id,
            non_repeaters: 0,
            max_repetitions: 10,
            variable_bindings,
        };

        let get_request: GetBulkRequest = GetBulkRequest(pdu);

        let message: Message<GetBulkRequest> = Message {
            version: 1.into(),
            community: community.to_string().into(),
            data: get_request.into(),
        };

        // Send the message through an UDP socket
        let decoded = get_data_from_udp(target, message)?;

        let completed =
            retval.build_response_with_labels(decoded, &oid, snmp_name, labels, true)?;
        if completed {
            break;
        }
        oid_tab = &retval.last_oid;
    }
    Ok(retval)
}

impl SnmpResult {
    /// Stores a decoded value under `key`, appending to the existing vector when
    /// this key has already been seen (walk operations collect one entry per OID).
    ///
    /// # Panics
    /// Panics if a key that previously held a numeric value is fed a string (or
    /// vice versa) — this would mean a single OID column changed SNMP type
    /// mid-collection, which indicates a malformed response.
    fn store(&mut self, key: String, typ: ValueType) {
        match typ {
            ValueType::String(s) => {
                self.items
                    .entry(key)
                    .and_modify(|e| match e {
                        ExprResult::StrVector(v) => v.push(s.clone()),
                        _ => {
                            panic!("SNMP value type changed from numeric to string mid-collection")
                        }
                    })
                    .or_insert_with(|| ExprResult::StrVector(vec![s]));
            }
            _ => {
                let value = typ.as_f64();
                self.items
                    .entry(key)
                    .and_modify(|e| match e {
                        ExprResult::Vector(v) => v.push(value),
                        _ => {
                            panic!("SNMP value type changed from string to numeric mid-collection")
                        }
                    })
                    .or_insert_with(|| ExprResult::Vector(vec![value]));
            }
        }
    }

    /// Processes one bulk response page: stores each variable's decoded value
    /// and, for walk operations, detects when the response has moved past the
    /// requested subtree.
    ///
    /// `key_for` maps a variable (by index and full OID name) to the key(s) its
    /// value should be stored under; returning an empty vector skips it.
    ///
    /// # Returns
    /// `true` if the walk should terminate (for walk operations)
    fn process_response(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        walk: bool,
        mut key_for: impl FnMut(usize, &str) -> Vec<String>,
    ) -> Result<bool> {
        let mut completed = false;

        if let Pdus::Response(resp) = &decoded.data {
            for (idx, var) in resp.0.variable_bindings.iter().enumerate() {
                let name = var.name.to_string();
                self.last_oid = oid_to_vec(&name)?;

                if walk && (!name.starts_with(oid) || var.value.eq(&EndOfMibView)) {
                    completed = true;
                    break;
                }

                let Some(typ) = value_from_varbind(&var.value)? else {
                    continue;
                };

                for key in key_for(idx, &name) {
                    self.store(key, typ.clone());
                }
            }
        }
        Ok(completed)
    }

    /// Parses an SNMP response and organizes values by label: the last segment
    /// of each OID identifies the column, and matching values are stored under
    /// `{snmp_name}.{label}`.
    fn build_response_with_labels<'a>(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        snmp_name: &str,
        labels: &'a HashMap<String, String>,
        walk: bool,
    ) -> Result<bool> {
        self.process_response(decoded, oid, walk, |_idx, name| {
            let prefix = name.rfind('.').map_or(name, |i| &name[..i]);
            labels
                .iter()
                .filter(|(label, _)| prefix.ends_with(label.as_str()))
                .map(|(_, out_name)| format!("{}.{}", snmp_name, out_name))
                .collect()
        })
    }

    /// Parses an SNMP response from a get request, storing each variable under
    /// its corresponding entry in `names`.
    fn build_response_with_names<'a>(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        names: &Vec<&str>,
        walk: bool,
    ) -> Result<bool> {
        self.process_response(decoded, oid, walk, |idx, _name| {
            vec![names[idx].to_string()]
        })
    }

    /// Parses an SNMP response and stores every variable's value under a single
    /// logical name (used for plain walks).
    fn build_response<'a>(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        snmp_name: &str,
        walk: bool,
    ) -> Result<bool> {
        self.process_response(decoded, oid, walk, |_idx, _name| {
            vec![snmp_name.to_string()]
        })
    }
}

mod tests {
    use std::println;

    use super::*;

    // #[test]
    // fn test_snmp_get() {
    //     let result = r_snmp_get("127.0.0.1:161", "1.3.6.1.2.1.1.1.0", "public");
    //     let expected = SnmpResult {
    //         variables: vec![SnmpVariable{
    //             "1.3.6.1.2.1.1.1.0".to_string(),
    //             "Linux CNTR-PORT-A104 6.1.0-31-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.128-1 (2025-02-07) x86_64".to_string()}],
    //     };
    //     assert_eq!(result, expected);
    // }
    //
    #[test]
    fn test_snmp_bulk_walk() {
        let result = snmp_bulk_walk(
            "127.0.0.1:161",
            "2",
            "public",
            "1.3.6.1.2.1.25.3.3.1.2",
            "test_name",
        );
        println!("result : {:#?}", result);
        for v in result.unwrap().items {
            let name = &v.0;
            assert!(name.starts_with("1.3.6.1.2.1.25.3.3.1.2"));
        }
    }
    //
    //    #[test]
    //    fn test_snmp_bulk_walk() {
    //        let result = r_snmp_bulk_walk("127.0.0.1:161", "2c", "public", "1.3.6.1.2.1.25.3.3.1.2");
    //        let re = Regex::new(r"[0-9]+").unwrap();
    //        assert!(result.variables.len() > 0);
    //        for v in result.variables.iter() {
    //            println!("{:?}", v);
    //            let name = &v.name;
    //            assert!(name.starts_with("1.3.6.1.2.1.25.3.3.1.2"));
    //            assert!(re.is_match(&v.value));
    //        }
    //    }
}
