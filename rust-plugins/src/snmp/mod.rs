//! SNMP protocol communication using SNMPv2c bulk get/walk operations.
//!
//! Provides functions to query SNMP agents via UDP, parse responses,
//! and store results as vectors or scalars for metric computation.
//!
//! Walks (`snmp_bulk_walk`, `snmp_bulk_walk_with_labels`) issue repeated
//! GetBulk requests until the response leaves the requested subtree or the
//! agent signals `EndOfMibView`. All standard SNMP value types (INTEGER,
//! OCTET STRING, OBJECT IDENTIFIER, IpAddress, Counter32/64, Gauge32/Unsigned32,
//! TimeTicks, Opaque) are decoded; see `value_from_varbind`.

extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;

use crate::Error::InvalidOidParser;
use crate::compute::ast::ExprResult;
use crate::generic::error::Error::CollectTimeout;
use crate::generic::error::Error::EmptyResponse;
use crate::generic::error::Error::FailedToConnectToHost;
use crate::generic::error::Error::InvalidSnmpPduDecode;
use crate::generic::error::Error::InvalidSnmpPduEncode;
use crate::generic::error::Error::InvalidSnmpType;
use crate::generic::error::Error::InvalidSnmpValue;
use crate::generic::error::Error::OidNotIncreasing;
use crate::generic::error::Error::RequestTimeout;
use crate::generic::error::Error::SnmpAgentError;
use crate::generic::error::Error::WalkTooLarge;
use crate::generic::error::Result;
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
use std::time::{Duration, Instant};

/// Maximum size of a UDP datagram; SNMP bulk responses can be large,
/// a smaller buffer would silently truncate them and break BER decoding.
const UDP_BUFFER_SIZE: usize = 65535;

/// Upper bound on the number of values a single walk may collect. Protects
/// the plugin against a buggy or malicious agent that returns endless data:
/// well beyond any real table (a 48-port switch's ifTable is a few thousand
/// entries), but finite.
const MAX_WALK_VARBINDS: usize = 100_000;

/// Connection parameters shared by every SNMP request of a collection.
#[derive(Debug, Clone)]
pub struct SnmpConfig {
    /// Target address in `host:port` format.
    pub target: String,
    /// SNMP version (only `2c` is supported today).
    pub version: String,
    /// SNMP community string.
    pub community: String,
    /// Receive timeout for a single request attempt (mirror of the Perl
    /// `--timeout`, default 1s).
    pub timeout: Duration,
    /// Number of retries after a timed-out attempt (default 2; total
    /// attempts = retries + 1).
    pub retries: u32,
    /// Global time budget for the whole collection (all gets and walks).
    /// Protects the poller from a slow agent: centengine kills plugins
    /// after its own timeout, this one lets us exit with a clean UNKNOWN
    /// message before being killed.
    pub collect_timeout: Duration,
}

impl SnmpConfig {
    /// Computes the collection deadline from now.
    pub fn deadline(&self) -> Instant {
        Instant::now() + self.collect_timeout
    }
}

/// Standard names of the SNMP `error-status` field (RFC 3416).
fn error_status_name(status: u32) -> &'static str {
    match status {
        0 => "noError",
        1 => "tooBig",
        2 => "noSuchName",
        3 => "badValue",
        4 => "readOnly",
        5 => "genErr",
        6 => "noAccess",
        7 => "wrongType",
        8 => "wrongLength",
        9 => "wrongEncoding",
        10 => "wrongValue",
        11 => "noCreation",
        12 => "inconsistentValue",
        13 => "resourceUnavailable",
        14 => "commitFailed",
        15 => "undoFailed",
        16 => "authorizationError",
        17 => "notWritable",
        18 => "inconsistentName",
        _ => "unknown",
    }
}

/// Outcome of validating a received SNMP message against the request.
#[derive(Debug, PartialEq)]
enum ResponseCheck {
    /// The response matches the request and carries no agent error.
    Valid,
    /// The datagram does not belong to this request (wrong request-id,
    /// wrong community or unexpected PDU type): discard it and keep
    /// waiting — e.g. a late retransmission from a previous attempt.
    Discard,
}

/// Validates a received message: PDU type, request-id correlation,
/// community echo and agent error status.
///
/// # Returns
/// * `Ok(Valid)` — response usable by the caller,
/// * `Ok(Discard)` — datagram unrelated to this request, keep waiting,
/// * `Err(SnmpAgentError)` — the agent answered with an error status.
fn check_response(
    message: &Message<Pdus>,
    expected_id: i32,
    community: &str,
) -> Result<ResponseCheck> {
    let Pdus::Response(resp) = &message.data else {
        warn!("Received a non-Response SNMP PDU, discarding");
        return Ok(ResponseCheck::Discard);
    };
    if resp.0.request_id != expected_id {
        warn!(
            "Received response for request-id {} while waiting for {}, discarding",
            resp.0.request_id, expected_id
        );
        return Ok(ResponseCheck::Discard);
    }
    if message.community.as_ref() != community.as_bytes() {
        warn!("Received response with a mismatched community, discarding");
        return Ok(ResponseCheck::Discard);
    }
    if resp.0.error_status != 0 {
        return Err(SnmpAgentError {
            name: error_status_name(resp.0.error_status),
            status: resp.0.error_status,
            index: resp.0.error_index,
        });
    }
    Ok(ResponseCheck::Valid)
}

/// The SNMP value type decoded from a single OID's response.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ValueType {
    /// A 64-bit signed integer (covers INTEGER and TimeTicks).
    Integer(i64),
    /// A textual value (OCTET STRING, OBJECT IDENTIFIER, IpAddress, Opaque).
    String(String),
    /// A 64-bit unsigned counter (covers Counter32, Counter64, and
    /// Gauge32/Unsigned32 — none of these ever go negative or need signed
    /// arithmetic, so they share one representation).
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
        VarBindValue::Value(value) => value,
        _ => {
            warn!("SNMP varbind value is Empty, returning Ok(None)");
            return Ok(None);
        }
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
/// Stores collected values keyed by name, and tracks the last OID
/// for walk-based operations.
///
/// Exemple of output of :
/// SnmpResult { last_oid: [1,3,6,1,2,1,25,],
///             items: {
///                "cpu": Vector( [
///                        6.0,
///                        6.0,
///            ])}}
///
#[derive(Debug)]
pub struct SnmpResult {
    /// Collected values from this SNMP query, indexed by OID name.
    pub items: HashMap<String, ExprResult>,
    last_oid: Vec<u32>,
    /// Number of in-subtree variable bindings processed by this walk,
    /// checked against [`MAX_WALK_VARBINDS`].
    processed: usize,
}

/// Retrieves values for multiple OIDs in a single bulk request.
///
/// # Arguments
/// * `config` - Connection parameters (target, community, timeouts, retries)
/// * `deadline` - Global deadline of the whole collection
/// * `non_repeaters` - Number of non-repeating OIDs (typically 0 or 1)
/// * `max_repetitions` - Maximum repetitions per OID
/// * `oid` - Vector of OID strings to query
/// * `names` - Vector of logical names (one per OID)
///
/// # Returns
/// An Result<[`SnmpResult`]> containing the retrieved values indexed by name, or an error
///

pub fn snmp_bulk_get<'a>(
    config: &SnmpConfig,
    deadline: Instant,
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

    let mut retval = SnmpResult::new(HashMap::new());
    let request_id: i32 = 1;

    let variable_bindings = oids_tab
        .iter()
        .map(|x| VarBind {
            name: ObjectIdentifier::new_unchecked(x.to_vec().into()),
            value: VarBindValue::Unspecified,
        })
        .collect::<Vec<VarBind>>();

    let message = build_bulk_message(
        config,
        request_id,
        variable_bindings,
        non_repeaters,
        max_repetitions,
    );
    let decoded = send_request(config, deadline, request_id, &message)?;

    let _completed = retval.build_response_with_names(decoded, "", names, false)?;
    Ok(retval)
}

/// Walks a subtree of OIDs using repeated bulk requests until the subtree is exhausted.
///
/// Continues retrieving values until the response leaves the requested
/// subtree or the agent replies with `EndOfMibView`. Any transport failure
/// (including a read timeout) is propagated as an `Err`, not a partial result.
///
/// # Arguments
/// * `config` - Connection parameters (target, community, timeouts, retries)
/// * `deadline` - Global deadline of the whole collection
/// * `oid` - The base OID to walk
/// * `snmp_name` - Logical name for collected values
///
/// # Returns
/// An [`SnmpResult`] containing all values under the specified OID
pub fn snmp_bulk_walk<'a>(
    config: &SnmpConfig,
    deadline: Instant,
    oid: &str,
    snmp_name: &str,
) -> Result<SnmpResult> {
    let oid_init = oid_to_vec(oid)?;
    let mut oid_tab = oid_init.clone();
    let mut retval = SnmpResult::new(HashMap::new());
    let mut request_id: i32 = 1;
    loop {
        let variable_bindings = vec![VarBind {
            name: ObjectIdentifier::new_unchecked(oid_tab.to_vec().into()),
            value: VarBindValue::Unspecified,
        }];

        let message = build_bulk_message(config, request_id, variable_bindings, 0, 10);
        let decoded = send_request(config, deadline, request_id, &message)?;
        // One id per request: a late response to a previous iteration can
        // never be mistaken for the current one.
        request_id = request_id.wrapping_add(1);

        let completed = retval.build_response(decoded, oid, snmp_name, true)?;

        if completed {
            break;
        }
        oid_tab = retval.last_oid.clone();
    }
    Ok(retval)
}

/// Walks a subtree and organizes results by label matches.
///
/// Used for tabular SNMP data where the last segment of an OID identifies
/// the column (labeled in the `labels` map), and values are organized per label.
/// Like [`snmp_bulk_walk`], it stops once the response leaves the requested
/// subtree or the agent replies with `EndOfMibView`.
///
/// # Arguments
/// * `config` - Connection parameters (target, community, timeouts, retries)
/// * `deadline` - Global deadline of the whole collection
/// * `oid` - The base OID to walk
/// * `snmp_name` - Logical name prefix for collected values
/// * `labels` - Map of label identifiers to logical names
///
/// # Returns
/// An [`SnmpResult`] with values organized by label as separate vectors
pub fn snmp_bulk_walk_with_labels<'a>(
    config: &SnmpConfig,
    deadline: Instant,
    oid: &str,
    snmp_name: &str,
    labels: &'a HashMap<String, String>,
) -> Result<SnmpResult> {
    let oid_init = oid_to_vec(oid)?;
    let mut oid_tab = oid_init.clone();
    let mut retval = SnmpResult::new(HashMap::new());
    let mut request_id: i32 = 1;

    loop {
        let variable_bindings = vec![VarBind {
            name: ObjectIdentifier::new_unchecked(oid_tab.to_vec().into()),
            value: VarBindValue::Unspecified,
        }];

        let message = build_bulk_message(config, request_id, variable_bindings, 0, 10);
        // Send the message through an UDP socket
        let decoded = send_request(config, deadline, request_id, &message)?;
        // One id per request: a late response to a previous iteration can
        // never be mistaken for the current one.
        request_id = request_id.wrapping_add(1);

        let completed =
            retval.build_response_with_labels(decoded, oid, snmp_name, labels, true)?;
        if completed {
            break;
        }
        oid_tab = retval.last_oid.clone();
    }
    Ok(retval)
}

impl SnmpResult {
    /// Creates a new `SnmpResult` with the given items map.
    pub fn new(items: HashMap<String, ExprResult>) -> SnmpResult {
        SnmpResult {
            items,
            last_oid: Vec::new(),
            processed: 0,
        }
    }

    /// Stores a decoded value under `key`, appending to the existing vector when
    /// this key has already been seen (walk operations collect one entry per OID).
    /// Return an error when the key previously held a String and inserting a number (and vice-versa)
    /// this would mean a single OID column changed SNMP type mid-collection, which indicates a malformed response.
    fn store(&mut self, key: String, typ: ValueType) -> Result<()> {
        match typ {
            ValueType::String(s) => match self.items.entry(key) {
                std::collections::hash_map::Entry::Occupied(mut e) => match e.get_mut() {
                    ExprResult::StrVector(v) => v.push(s),
                    _ => {
                        return Err(InvalidSnmpValue {
                            detail: "SNMP value type changed from numeric to string mid-collection"
                                .to_string(),
                        });
                    }
                },
                std::collections::hash_map::Entry::Vacant(e) => {
                    e.insert(ExprResult::StrVector(vec![s]));
                }
            },
            _ => {
                let value = typ.as_f64();
                match self.items.entry(key) {
                    std::collections::hash_map::Entry::Occupied(mut e) => match e.get_mut() {
                        ExprResult::Vector(v) => v.push(value),
                        _ => {
                            return Err(InvalidSnmpValue {
                                detail:
                                    "SNMP value type changed from string to numeric mid-collection"
                                        .to_string(),
                            });
                        }
                    },

                    std::collections::hash_map::Entry::Vacant(e) => {
                        e.insert(ExprResult::Vector(vec![value]));
                    }
                }
            }
        }
        Ok(())
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

                // A terminator (out-of-subtree OID or EndOfMibView) is not
                // real walked data: some agents echo a stale or unrelated
                // OID on it, so it must not be subjected to the
                // monotonicity/cap guards below, only checked for
                // termination.
                if walk && (!name.starts_with(oid) || var.value.eq(&EndOfMibView)) {
                    completed = true;
                    break;
                }

                let arcs = oid_to_vec(&name)?;

                // During a walk, OIDs must be strictly increasing — both
                // inside a batch and across batches (`last_oid` carries the
                // previous position). An agent that repeats or goes
                // backwards would otherwise loop the walk forever (classic
                // snmpwalk "OID not increasing" guard).
                if walk && !self.last_oid.is_empty() && arcs <= self.last_oid {
                    return Err(OidNotIncreasing { oid: name });
                }
                self.last_oid = arcs;

                // Hard bound on the amount of data a single walk may
                // return: protects against an agent streaming endless values.
                if walk {
                    self.processed += 1;
                    if self.processed > MAX_WALK_VARBINDS {
                        return Err(WalkTooLarge {
                            max: MAX_WALK_VARBINDS,
                        });
                    }
                }

                let Some(typ) = value_from_varbind(&var.value)? else {
                    continue;
                };

                for key in key_for(idx, &name) {
                    _ = self.store(key, typ.clone())?;
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

/// Helper function to parse a numerical oid and return a vector containing the list of id composing the oid.
///
/// # Arguments
/// * `oid` - string in the form '.1.3.6.1.2', the first dot being optional.
///
/// # Returns
/// An array of unsigned numbers representing the oid, or an error if the oid
/// is empty or one of its parts is not a number.
///
fn oid_to_vec(oid: &str) -> Result<Vec<u32>> {
    let mut oid_u32: Vec<u32> = vec![];
    if oid.is_empty() {
        return Err(InvalidOidParser {
            oid: "no value given".to_string(),
        });
    }
    for id in oid.split('.').skip_while(|d| d.is_empty()) {
        // OIDs are generally given starting with a '.' so the first digit may be empty
        oid_u32.push(id.parse::<u32>().map_err(|_| InvalidOidParser {
            oid: oid.to_string(),
        })?);
    }
    return Ok(oid_u32);
}

/// Builds the v2c GetBulk message for the given variable bindings.
fn build_bulk_message(
    config: &SnmpConfig,
    request_id: i32,
    variable_bindings: Vec<VarBind>,
    non_repeaters: u32,
    max_repetitions: u32,
) -> Message<GetBulkRequest> {
    let pdu = BulkPdu {
        request_id,
        variable_bindings,
        non_repeaters,
        max_repetitions,
    };
    Message {
        version: 1.into(),
        community: config.community.as_bytes().into(),
        data: GetBulkRequest(pdu),
    }
}

/// Sends a GetBulk request and waits for its matching response, honoring
/// per-attempt timeouts, retries and the global collection deadline.
/// This function is blocking.
///
/// The socket is `connect`ed to the target, so the kernel filters datagrams
/// from other sources. On top of that, every received message is validated
/// by [`check_response`] (request-id correlation, community echo, agent
/// error status); unrelated datagrams are discarded and the wait continues.
///
/// # Arguments
/// * `config` - Connection parameters (target, community, timeouts, retries)
/// * `deadline` - Global deadline of the whole collection
/// * `request_id` - Identifier of this request, verified in the response
/// * `message` - The request message to send
///
/// # Returns
/// The validated response, or a typed error (`CollectTimeout`,
/// `RequestTimeout`, `SnmpAgentError`, ...)
// In tests, the transport is replaced by an in-memory fake agent (see
// `tests::fake_snmp_agent`) so the request/response loop in `snmp_bulk_walk`
// and friends can be exercised without a real network; the deadline check
// still runs so `expired_deadline_stops_the_collection_before_sending` can
// exercise it without touching the network either.
#[cfg(test)]
fn send_request(
    config: &SnmpConfig,
    deadline: Instant,
    request_id: i32,
    message: &Message<GetBulkRequest>,
) -> Result<Message<Pdus>> {
    if Instant::now() >= deadline {
        return Err(CollectTimeout {
            seconds: config.collect_timeout.as_secs(),
        });
    }
    let decoded = tests::fake_snmp_agent(message.clone())?;
    match check_response(&decoded, request_id, &config.community)? {
        ResponseCheck::Valid => Ok(decoded),
        ResponseCheck::Discard => Err(RequestTimeout {
            url: config.target.clone(),
            attempts: 1,
            timeout: config.timeout.as_secs(),
        }),
    }
}
#[cfg(not(test))]
fn send_request(
    config: &SnmpConfig,
    deadline: Instant,
    request_id: i32,
    message: &Message<GetBulkRequest>,
) -> Result<Message<Pdus>> {
    let encoded: Vec<u8> = rasn::der::encode(message).map_err(|_| InvalidSnmpPduEncode {})?;
    let socket = UdpSocket::bind("0.0.0.0:0")?;
    socket.connect(&config.target)?;
    let mut buf = vec![0u8; UDP_BUFFER_SIZE];

    let attempts = config.retries + 1;
    for attempt in 1..=attempts {
        // Enforce the global collection budget before spending more time.
        let now = Instant::now();
        if now >= deadline {
            return Err(CollectTimeout {
                seconds: config.collect_timeout.as_secs(),
            });
        }
        let attempt_deadline = std::cmp::min(now + config.timeout, deadline);

        let sent = socket.send(&encoded).map_err(|e| FailedToConnectToHost {
            url: config.target.clone(),
            os: e.to_string(),
        })?;
        // UDP send is all-or-nothing: a partial send cannot happen, the
        // datagram is either fully sent or the call errors out above.
        assert!(sent == encoded.len());
        trace!(
            "request {} attempt {}/{} sent to {}",
            request_id, attempt, attempts, config.target
        );

        // Receive until this attempt's deadline; discard unrelated datagrams.
        loop {
            let remaining = attempt_deadline.saturating_duration_since(Instant::now());
            if remaining.is_zero() {
                break; // attempt timed out, retry
            }
            socket.set_read_timeout(Some(remaining))?;
            let received = match socket.recv(buf.as_mut_slice()) {
                Ok(n) => n,
                Err(_) => break, // timeout or transient error: retry
            };
            trace!("Received {} bytes", received);
            if received == 0 {
                return Err(EmptyResponse {});
            }
            let decoded: Message<Pdus> = rasn::ber::decode(&buf[0..received])
                .map_err(|e| InvalidSnmpPduDecode { err: e.to_string() })?;
            match check_response(&decoded, request_id, &config.community)? {
                ResponseCheck::Valid => return Ok(decoded),
                ResponseCheck::Discard => continue,
            }
        }
    }

    Err(RequestTimeout {
        url: config.target.clone(),
        attempts,
        timeout: config.timeout.as_secs(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use rasn::types::{FixedOctetString, Integer, OctetString};
    // `ApplicationSyntax`'s fields (Counter32, Unsigned32, IpAddress, TimeTicks)
    // are type aliases, and tuple structs can't be constructed through an
    // alias, so tests build values via the concrete v1 types instead.
    use rasn_smi::v1::{Counter, Gauge, IpAddress, TimeTicks};
    use rasn_smi::v2::{Counter64, ToOpaque};
    use rasn_snmp::v2::{Pdu, Response};

    /// Base OID for a fake table with more rows (12) than `max_repetitions`
    /// (hardcoded to 10 in `snmp_bulk_walk`), so a walk over it forces two
    /// GetBulk round trips. The agent ends the walk the way a real device
    /// would: by returning the next OID in the tree, which lies outside this
    /// subtree.
    const CPU_TABLE_OID: &str = "1.3.6.1.2.1.25.3.3.1.2";
    const CPU_TABLE_LEN: i64 = 12;
    const CPU_TABLE_NEXT_OID: &str = "1.3.6.1.2.1.25.3.3.2.1";

    /// Base OID for a fake table that ends with `EndOfMibView` instead of an
    /// out-of-subtree OID, exercising the other walk-termination path.
    const SHORT_TABLE_OID: &str = "1.3.6.1.4.1.99999.1";
    const SHORT_TABLE_LEN: i64 = 2;

    /// Sentinel OID whose requests simulate a transport failure.
    const TRANSPORT_ERROR_OID: &str = "1.2.3.4";

    fn integer_varbind(oid: &str, value: i64) -> VarBind {
        VarBind {
            name: ObjectIdentifier::new_unchecked(oid_to_vec(oid).unwrap().into()),
            value: VarBindValue::Value(ObjectSyntax::Simple(SimpleSyntax::Integer(value.into()))),
        }
    }

    /// A fake SNMP agent: given a GetBulk request, returns canned rows so
    /// `snmp_bulk_walk`'s request/response loop can be exercised without a
    /// real network. The scenario is picked purely from the requested OID, so
    /// tests stay deterministic and safe to run in parallel.
    pub(super) fn fake_snmp_agent(message: Message<GetBulkRequest>) -> Result<Message<Pdus>> {
        let request = message.data.0;
        let requested_str = request.variable_bindings[0].name.to_string();

        if requested_str.starts_with(TRANSPORT_ERROR_OID) {
            return Err(EmptyResponse {});
        }

        // A "get" request (snmp_bulk_get) asks for several distinct,
        // single-instance OIDs in one request, unlike a walk which always
        // requests exactly one OID per round trip. Answer each directly.
        if request.variable_bindings.len() > 1 {
            let oids: Vec<String> = request
                .variable_bindings
                .iter()
                .map(|vb| vb.name.to_string())
                .collect();
            let vars = oids
                .iter()
                .enumerate()
                .map(|(i, oid)| (oid.as_str(), (i as i64 + 1) * 100))
                .collect();
            return Ok(response_message(vars));
        }

        let (table_prefix, table_len, out_of_subtree): (&str, i64, Option<(&str, i64)>) =
            if requested_str.starts_with(CPU_TABLE_OID) {
                (
                    CPU_TABLE_OID,
                    CPU_TABLE_LEN,
                    Some((CPU_TABLE_NEXT_OID, 999)),
                )
            } else if requested_str.starts_with(SHORT_TABLE_OID) {
                (SHORT_TABLE_OID, SHORT_TABLE_LEN, None)
            } else {
                (requested_str.as_str(), 0, None)
            };

        let requested = oid_to_vec(&requested_str)?;
        let max_repetitions = request.max_repetitions as i64;
        let mut variable_bindings = vec![];
        for i in 1..=table_len {
            let oid = format!("{}.{}", table_prefix, i);
            if oid_to_vec(&oid)? > requested && (variable_bindings.len() as i64) < max_repetitions {
                variable_bindings.push(integer_varbind(&oid, i * 10));
            }
        }
        if (variable_bindings.len() as i64) < max_repetitions {
            match out_of_subtree {
                Some((oid, value)) => variable_bindings.push(integer_varbind(oid, value)),
                // A real agent fills unused repetitions with EndOfMibView once
                // it reaches the end of its whole MIB, not just this subtree.
                None => variable_bindings.push(VarBind {
                    name: ObjectIdentifier::new_unchecked(requested.into()),
                    value: VarBindValue::EndOfMibView,
                }),
            }
        }

        Ok(Message {
            version: 1.into(),
            community: "public".as_bytes().into(),
            data: Pdus::Response(Response(Pdu {
                request_id: request.request_id,
                error_status: 0,
                error_index: 0,
                variable_bindings,
            })),
        })
    }

    fn test_config() -> SnmpConfig {
        SnmpConfig {
            target: "test:161".to_string(),
            version: "2c".to_string(),
            community: "public".to_string(),
            timeout: Duration::from_secs(1),
            retries: 2,
            collect_timeout: Duration::from_secs(50),
        }
    }

    #[test]
    fn test_snmp_bulk_walk() {
        let config = test_config();
        // collects every row across multiple bulk pages
        let result = snmp_bulk_walk(&config, config.deadline(), CPU_TABLE_OID, "cpu").unwrap();

        match result.items.get("cpu").unwrap() {
            ExprResult::Vector(v) => assert_eq!(
                v,
                &(1..=CPU_TABLE_LEN)
                    .map(|i| (i * 10) as f64)
                    .collect::<Vec<_>>()
            ),
            other => panic!("expected a numeric vector, got {:?}", other),
        }

        // terminates on end of mib view
        let result = snmp_bulk_walk(&config, config.deadline(), SHORT_TABLE_OID, "short").unwrap();

        match result.items.get("short").unwrap() {
            ExprResult::Vector(v) => assert_eq!(v, &vec![10.0, 20.0]),
            other => panic!("expected a numeric vector, got {:?}", other),
        }

        //propagates transport errors
        let result = snmp_bulk_walk(&config, config.deadline(), TRANSPORT_ERROR_OID, "x");
        assert!(result.is_err());
    }

    #[test]
    fn test_snmp_bulk_get() {
        let config = test_config();
        // fetches several distinct OIDs in a single round trip
        let result = snmp_bulk_get(
            &config,
            config.deadline(),
            2,
            0,
            &vec!["1.3.6.1.2.1.1.3.0", "1.3.6.1.2.1.1.5.0"],
            &vec!["uptime", "name"],
        )
        .unwrap();

        assert_eq!(
            result.items.get("uptime").unwrap(),
            &ExprResult::Vector(vec![100.0])
        );
        assert_eq!(
            result.items.get("name").unwrap(),
            &ExprResult::Vector(vec![200.0])
        );

        // propagates transport errors
        let result = snmp_bulk_get(
            &config,
            config.deadline(),
            1,
            0,
            &vec![TRANSPORT_ERROR_OID],
            &vec!["x"],
        );
        assert!(result.is_err());

        // propagates invalid-oid errors before any network call
        let result = snmp_bulk_get(&config, config.deadline(), 1, 0, &vec![""], &vec!["x"]);
        assert!(result.is_err());
    }

    #[test]
    fn test_snmp_bulk_walk_with_labels() {
        let config = test_config();
        // collects every row across multiple bulk pages, grouped by label
        let mut labels = HashMap::new();
        // label contain the oid last number as key and the name of the property as value.
        labels.insert("2".to_string(), "core".to_string());
        let result = snmp_bulk_walk_with_labels(
            &config,
            config.deadline(),
            CPU_TABLE_OID,
            "cpu",
            &labels,
        )
        .unwrap();
        match result.items.get("cpu.core").unwrap() {
            ExprResult::Vector(v) => assert_eq!(
                v,
                &(1..=CPU_TABLE_LEN)
                    .map(|i| (i * 10) as f64)
                    .collect::<Vec<_>>()
            ),
            other => panic!("expected a numeric vector, got {:?}", other),
        }

        // terminates on end of mib view
        let mut labels = HashMap::new();
        labels.insert("1".to_string(), "val".to_string());
        let result = snmp_bulk_walk_with_labels(
            &config,
            config.deadline(),
            SHORT_TABLE_OID,
            "short",
            &labels,
        )
        .unwrap();

        match result.items.get("short.val").unwrap() {
            ExprResult::Vector(v) => assert_eq!(v, &vec![10.0, 20.0]),
            other => panic!("expected a numeric vector, got {:?}", other),
        }

        // propagates transport errors
        let result = snmp_bulk_walk_with_labels(
            &config,
            config.deadline(),
            TRANSPORT_ERROR_OID,
            "x",
            &labels,
        );
        assert!(result.is_err());

        // propagates invalid-oid errors before any network call
        let result =
            snmp_bulk_walk_with_labels(&config, config.deadline(), "", "x", &labels);
        assert!(result.is_err());
    }

    // ---- Protocol hardening (quality plan, chantier A) ----------------------

    fn response_full(
        request_id: i32,
        error_status: u32,
        community: &str,
        bindings: Vec<VarBind>,
    ) -> Message<Pdus> {
        Message {
            version: 1.into(),
            community: community.as_bytes().into(),
            data: Pdus::Response(Response(Pdu {
                request_id,
                error_status,
                error_index: 3,
                variable_bindings: bindings,
            })),
        }
    }

    #[test]
    fn error_status_names_follow_rfc3416() {
        assert_eq!(error_status_name(0), "noError");
        assert_eq!(error_status_name(1), "tooBig");
        assert_eq!(error_status_name(2), "noSuchName");
        assert_eq!(error_status_name(5), "genErr");
        assert_eq!(error_status_name(16), "authorizationError");
        assert_eq!(error_status_name(99), "unknown");
    }

    #[test]
    fn check_response_accepts_a_matching_response() {
        let msg = response_full(42, 0, "public", vec![]);
        let res = check_response(&msg, 42, "public").expect("no agent error");
        assert_eq!(res, ResponseCheck::Valid);
    }

    #[test]
    fn check_response_discards_a_mismatched_request_id() {
        // A late retransmission from a previous request must be discarded,
        // not consumed as the answer to the current one.
        let msg = response_full(41, 0, "public", vec![]);
        let res = check_response(&msg, 42, "public").expect("discard is not an error");
        assert_eq!(res, ResponseCheck::Discard);
    }

    #[test]
    fn check_response_discards_a_mismatched_community() {
        let msg = response_full(42, 0, "other", vec![]);
        let res = check_response(&msg, 42, "public").expect("discard is not an error");
        assert_eq!(res, ResponseCheck::Discard);
    }

    #[test]
    fn check_response_reports_agent_errors_with_their_standard_name() {
        // error_status 2 = noSuchName, error_index 3.
        let msg = response_full(42, 2, "public", vec![]);
        let err = check_response(&msg, 42, "public").expect_err("agent error expected");
        let text = err.to_string();
        assert!(text.contains("noSuchName"), "got: {}", text);
        assert!(text.contains("index 3"), "got: {}", text);
    }

    #[test]
    fn walk_rejects_a_non_increasing_oid() {
        // Second OID goes backwards: a buggy agent would loop the walk
        // forever without this guard.
        let msg = response_message(vec![("1.3.6.1.2.5", 1), ("1.3.6.1.2.4", 2)]);
        let mut result = SnmpResult::new(HashMap::new());
        let err = result.build_response(msg, "1.3.6.1.2", "v", true);
        assert!(err.is_err(), "backwards OID must be an error");

        // An OID equal to the previous one must fail too.
        let msg = response_message(vec![("1.3.6.1.2.5", 1), ("1.3.6.1.2.5", 2)]);
        let mut result = SnmpResult::new(HashMap::new());
        let err = result.build_response(msg, "1.3.6.1.2", "v", true);
        assert!(err.is_err(), "repeated OID must be an error");
    }

    #[test]
    fn walk_aborts_beyond_the_varbind_safety_bound() {
        // Feed MAX_WALK_VARBINDS + 1 increasing varbinds through the walk
        // path: the bound must trip instead of accumulating forever.
        let bindings: Vec<(String, i64)> = (0..=(MAX_WALK_VARBINDS as u32))
            .map(|i| (format!("1.3.6.1.2.{}", i + 1), 1))
            .collect();
        let msg = response_message(bindings.iter().map(|(oid, v)| (oid.as_str(), *v)).collect());
        let mut result = SnmpResult::new(HashMap::new());
        let err = result.build_response(msg, "1.3.6.1.2", "v", true);
        match err {
            Err(crate::generic::error::Error::WalkTooLarge { max }) => {
                assert_eq!(max, MAX_WALK_VARBINDS)
            }
            other => panic!("expected WalkTooLarge, got {:?}", other),
        }
    }

    #[test]
    fn expired_deadline_stops_the_collection_before_sending() {
        let config = test_config();
        let message = build_bulk_message(&config, 1, vec![], 0, 10);
        let past = Instant::now() - Duration::from_secs(1);
        let err = send_request(&config, past, 1, &message);
        match err {
            Err(crate::generic::error::Error::CollectTimeout { seconds }) => {
                assert_eq!(seconds, 50)
            }
            other => panic!("expected CollectTimeout, got {:?}", other),
        }
    }

    #[test]
    fn test_oid_to_vec() {
        let ok_tests_cases = vec![
            (
                "1.3.6.1.2.1.25.3.3.1.2",
                vec![1, 3, 6, 1, 2, 1, 25, 3, 3, 1, 2],
            ),
            ("1.3.6.4444", vec![1, 3, 6, 4444]),
            ("1.3.6.1", vec![1, 3, 6, 1]),
            (".1.3.6.1", vec![1, 3, 6, 1]),
        ];
        for (input, output) in ok_tests_cases {
            let result = oid_to_vec(input);
            assert_eq!(result.unwrap(), output);
        }

        let fail_tests_cases = vec![
            ".1..3.6.1",
            ".1.3.6.1.",
            ".1.string.6.1.",
            ".1,3,6.1.",
            "notAnOid",
            "",
        ];
        for input in fail_tests_cases {
            let result = oid_to_vec(input);
            assert!(result.is_err());
        }
    }

    #[test]
    fn value_from_varbind_returns_none_for_data_less_markers() {
        // These are legitimate agent responses (unset value, no such
        // object/instance, end of MIB view), not decode failures: they must
        // not error and must not panic.
        for marker in [
            VarBindValue::Unspecified,
            VarBindValue::NoSuchObject,
            VarBindValue::NoSuchInstance,
            VarBindValue::EndOfMibView,
        ] {
            assert_eq!(value_from_varbind(&marker).unwrap(), None);
        }
    }

    #[test]
    fn value_from_varbind_decodes_integer() {
        let value = VarBindValue::Value(ObjectSyntax::Simple(SimpleSyntax::Integer(
            Integer::from(42i64),
        )));
        assert_eq!(
            value_from_varbind(&value).unwrap(),
            Some(ValueType::Integer(42))
        );
    }

    #[test]
    fn value_from_varbind_rejects_an_integer_too_large_for_i64() {
        let value = VarBindValue::Value(ObjectSyntax::Simple(SimpleSyntax::Integer(
            Integer::from(u128::MAX),
        )));
        assert!(matches!(
            value_from_varbind(&value),
            Err(InvalidSnmpValue { .. })
        ));
    }

    #[test]
    fn value_from_varbind_lossily_decodes_non_utf8_octet_strings() {
        // Real devices put binary data (e.g. MAC addresses) in OCTET STRINGs,
        // so this must never panic like `String::from_utf8(..).unwrap()` would.
        let bytes = vec![0xC3, 0x28];
        let expected = String::from_utf8_lossy(&bytes).into_owned();
        let octets: OctetString = bytes.into();
        let value = VarBindValue::Value(ObjectSyntax::Simple(SimpleSyntax::String(octets)));
        assert_eq!(
            value_from_varbind(&value).unwrap(),
            Some(ValueType::String(expected))
        );
    }

    #[test]
    fn value_from_varbind_decodes_object_id_as_dotted_string() {
        let oid = ObjectIdentifier::new_unchecked(vec![1u32, 3, 6, 1].into());
        let value = VarBindValue::Value(ObjectSyntax::Simple(SimpleSyntax::ObjectId(oid)));
        assert_eq!(
            value_from_varbind(&value).unwrap(),
            Some(ValueType::String("1.3.6.1".to_string()))
        );
    }

    #[test]
    fn value_from_varbind_decodes_every_application_wide_type() {
        let ip = IpAddress(FixedOctetString::try_from([192u8, 168, 1, 1]).unwrap());
        let cases = vec![
            (
                ApplicationSyntax::Address(ip),
                ValueType::String("192.168.1.1".to_string()),
            ),
            (
                ApplicationSyntax::Counter(Counter(4_000_000_000)),
                ValueType::Counter64(4_000_000_000),
            ),
            (
                ApplicationSyntax::Ticks(TimeTicks(12345)),
                ValueType::Integer(12345),
            ),
            (
                ApplicationSyntax::BigCounter(Counter64(u64::MAX)),
                ValueType::Counter64(u64::MAX),
            ),
            (
                ApplicationSyntax::Unsigned(Gauge(999)),
                ValueType::Counter64(999),
            ),
        ];
        for (app, expected) in cases {
            let value = VarBindValue::Value(ObjectSyntax::ApplicationWide(app));
            assert_eq!(value_from_varbind(&value).unwrap(), Some(expected));
        }
    }

    #[test]
    fn value_from_varbind_decodes_arbitrary_as_a_hex_string() {
        let opaque = OctetString::from(vec![0xDE, 0xAD, 0xBE, 0xEF])
            .to_opaque()
            .unwrap();
        let raw_len = opaque.as_ref().len();
        let value = VarBindValue::Value(ObjectSyntax::ApplicationWide(
            ApplicationSyntax::Arbitrary(opaque),
        ));
        match value_from_varbind(&value).unwrap() {
            Some(ValueType::String(s)) => assert_eq!(s.len(), raw_len * 2),
            other => panic!("expected a hex string, got {:?}", other),
        }
    }

    #[test]
    fn store_accumulates_numeric_values_under_the_same_key() {
        let mut result = SnmpResult::new(HashMap::new());
        result
            .store("k".to_string(), ValueType::Integer(1))
            .unwrap();
        result
            .store("k".to_string(), ValueType::Counter64(2))
            .unwrap();

        assert_eq!(
            result.items.get("k").unwrap(),
            &ExprResult::Vector(vec![1.0, 2.0])
        );
    }

    #[test]
    fn store_accumulates_string_values_under_the_same_key() {
        let mut result = SnmpResult::new(HashMap::new());
        result
            .store("k".to_string(), ValueType::String("a".to_string()))
            .unwrap();

        result
            .store("k".to_string(), ValueType::String("b".to_string()))
            .unwrap();
        assert_eq!(
            result.items.get("k").unwrap(),
            &ExprResult::StrVector(vec!["a".to_string(), "b".to_string()])
        );
    }

    #[test]
    fn store_return_err_when_a_key_switches_from_numeric_to_string() {
        let mut result = SnmpResult::new(HashMap::new());

        result
            .store("k".to_string(), ValueType::Integer(1))
            .unwrap();
        // store fail when inserting string after integer in the same key
        assert!(
            result
                .store("k".to_string(), ValueType::String("oops".to_string()))
                .is_err()
        );
    }

    #[test]
    fn store_return_err_when_a_key_switches_from_string_to_numeric() {
        let mut result = SnmpResult::new(HashMap::new());
        result
            .store("k".to_string(), ValueType::String("oops".to_string()))
            .unwrap();
        // store fail when inserting string after integer in the same key
        assert!(
            result
                .store("k".to_string(), ValueType::Integer(1))
                .is_err()
        );
    }

    // ---- build_response_with_names / build_response_with_labels --------

    fn response_message(vars: Vec<(&str, i64)>) -> Message<Pdus> {
        Message {
            version: 1.into(),
            community: "public".as_bytes().into(),
            data: Pdus::Response(Response(Pdu {
                request_id: 1,
                error_status: 0,
                error_index: 0,
                variable_bindings: vars
                    .into_iter()
                    .map(|(oid, value)| integer_varbind(oid, value))
                    .collect(),
            })),
        }
    }

    #[test]
    fn build_response_with_names_maps_each_varbind_to_its_name() {
        let mut result = SnmpResult::new(HashMap::new());
        let decoded = response_message(vec![("1.3.6.1.2.1.1.3.0", 1), ("1.3.6.1.2.1.1.9.0", 2)]);

        let completed = result
            .build_response_with_names(decoded, "", &vec!["uptime", "count"], false)
            .unwrap();

        assert!(!completed);
        assert_eq!(
            result.items.get("uptime").unwrap(),
            &ExprResult::Vector(vec![1.0])
        );
        assert_eq!(
            result.items.get("count").unwrap(),
            &ExprResult::Vector(vec![2.0])
        );
    }

    #[test]
    fn build_response_with_labels_groups_values_by_matching_suffix() {
        let mut result = SnmpResult::new(HashMap::new());
        // Simulates an interface table: column .10 is "in", column .16 is "out".
        let decoded = response_message(vec![
            ("1.3.6.1.2.1.2.2.1.10.1", 100),
            ("1.3.6.1.2.1.2.2.1.16.1", 200),
        ]);
        let mut labels = HashMap::new();
        labels.insert("10".to_string(), "in".to_string());
        labels.insert("16".to_string(), "out".to_string());

        let completed = result
            .build_response_with_labels(decoded, "1.3.6.1.2.1.2.2.1", "iface", &labels, false)
            .unwrap();

        assert!(!completed);
        assert_eq!(
            result.items.get("iface.in").unwrap(),
            &ExprResult::Vector(vec![100.0])
        );
        assert_eq!(
            result.items.get("iface.out").unwrap(),
            &ExprResult::Vector(vec![200.0])
        );
    }
}
