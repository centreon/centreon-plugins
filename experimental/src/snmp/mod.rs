extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;

use log::{info, trace, warn};
use rasn::types::ObjectIdentifier;
use rasn_snmp::v2::Pdus;
use rasn_snmp::v2::VarBind;
use rasn_snmp::v2::VarBindValue;
use rasn_snmp::v2::{BulkPdu, Pdu};
use rasn_snmp::v2::{GetBulkRequest, GetNextRequest, GetRequest};
use rasn_snmp::v2c::Message;
use std::collections::BTreeMap;
use std::convert::TryInto;
use std::net::UdpSocket;

#[derive(Debug, PartialEq)]
pub struct SnmpSubResult<'a> {
    pub label: &'a str,
    pub value: &'a str,
    pub variables: Vec<SnmpVariable>,
}

#[derive(Debug, PartialEq)]
pub struct SnmpResult<'a> {
    pub labels: Vec<SnmpSubResult<'a>>,
}

#[derive(Debug, PartialEq)]
pub enum SnmpValue {
    Integer(i64),
    String(String),
}

#[derive(Debug, PartialEq)]
pub struct SnmpVariable {
    pub name: String,
    pub value: SnmpValue,
}

impl SnmpVariable {
    fn new(name: String, value: SnmpValue) -> SnmpVariable {
        SnmpVariable { name, value }
    }
}

impl<'a> SnmpResult<'a> {
    fn new(labels: &'a BTreeMap<String, String>) -> SnmpResult<'a> {
        let mut retval: Vec<SnmpSubResult> = Vec::new();
        retval.reserve(labels.len());
        for (label, value) in labels.iter() {
            let item = SnmpSubResult {
                label: &label,
                value: &value,
                variables: Vec::new(),
            };
            retval.push(item);
        }
        SnmpResult { labels: retval }
    }

    fn new_simple() -> SnmpResult<'a> {
        let label = SnmpSubResult{label: "", value: "", variables: Vec::new() };
        SnmpResult { labels: vec![label], }
    }

    fn add_variable(&mut self, idx: usize, name: String, value: SnmpValue) {
        self.labels[idx].variables.push(SnmpVariable::new(name, value));
    }

    fn get_last_oid(&self, idx: usize) -> &str {
        if self.labels.is_empty() {
            return "";
        }
        let last = self.labels[idx].variables.iter().last().unwrap();
        if last.name.is_empty() {
            return "";
        }
        last.name.as_str()
    }

    fn concat(&mut self, mut other: SnmpResult) {
        for v in other.labels.iter_mut() {
            for vv in self.labels.iter_mut() {
                if v.label == vv.label {
                    vv.variables.extend(v.variables);
                    break;
                }
            }
        }
    }
}

//pub fn snmp_get(target: &str, oid: &str, community: &str) -> SnmpResult {
//    let oid_tab = oid
//        .split('.')
//        .map(|x| x.parse::<u32>().unwrap())
//        .collect::<Vec<u32>>();
//
//    let request_id = 1;
//
//    let variable_bindings = vec![VarBind {
//        name: ObjectIdentifier::new_unchecked(oid_tab.into()),
//        value: VarBindValue::Unspecified,
//    }];
//
//    let pdu = Pdu {
//        request_id,
//        error_status: 0,
//        error_index: 0,
//        variable_bindings,
//    };
//
//    let get_request = GetRequest(pdu);
//
//    let message: rasn_snmp::v2c::Message<GetRequest> = Message {
//        version: 1.into(),
//        community: community.to_string().into(),
//        data: get_request.into(),
//    };
//
//    // Send the message through an UDP socket
//    let socket = UdpSocket::bind("0.0.0.0:0").unwrap();
//    socket.connect(target).expect("connect function failed");
//    let duration = std::time::Duration::from_millis(1000);
//    socket.set_read_timeout(Some(duration)).unwrap();
//
//    let encoded = rasn::der::encode(&message).unwrap();
//    let res = socket.send(&encoded).unwrap();
//    assert!(res == encoded.len());
//
//    let mut buf = [0; 1024];
//    let resp = socket.recv_from(buf.as_mut_slice()).unwrap();
//
//    trace!("Received {} bytes", resp.0);
//    assert!(resp.0 > 0);
//    let decoded: Message<Pdus> = rasn::ber::decode(&buf[0..resp.0]).unwrap();
//    build_response(decoded, "", {}, false).0
//}

//pub fn snmp_walk(target: &str, oid: &str) -> SnmpResult {
//    let community = "public";
//    let oid_tab = oid
//        .split('.')
//        .map(|x| x.parse::<u32>().unwrap())
//        .collect::<Vec<u32>>();
//
//    let mut retval = SnmpResult::new();
//    let mut request_id: i32 = 1;
//
//    let create_next_request = |id: i32, oid: &[u32]| -> Message<GetNextRequest> {
//        let variable_bindings = vec![VarBind {
//            name: ObjectIdentifier::new_unchecked(oid.to_vec().into()),
//            value: VarBindValue::Unspecified,
//        }];
//
//        let pdu = Pdu {
//            request_id: id,
//            error_status: 0,
//            error_index: 0,
//            variable_bindings,
//        };
//        let get_request: GetNextRequest = GetNextRequest(pdu);
//
//        Message {
//            version: 1.into(),
//            community: community.into(),
//            data: get_request.into(),
//        }
//    };
//
//    let mut message = create_next_request(request_id, &oid_tab);
//    // Send the message through an UDP socket
//    let socket = UdpSocket::bind("0.0.0.0:0").unwrap();
//    socket.connect(target).expect("connect function failed");
//    let duration = std::time::Duration::from_millis(1000);
//    socket.set_read_timeout(Some(duration)).unwrap();
//
//    loop {
//        let encoded: Vec<u8> = rasn::der::encode(&message).unwrap();
//        let res: usize = socket.send(&encoded).unwrap();
//        assert!(res == encoded.len());
//
//        let mut buf: [u8; 1024] = [0; 1024];
//        let resp: (usize, std::net::SocketAddr) = socket.recv_from(buf.as_mut_slice()).unwrap();
//
//        trace!("Received {} bytes", resp.0);
//        assert!(resp.0 > 0);
//        let decoded: Message<Pdus> = rasn::ber::decode(&buf[0..resp.0]).unwrap();
//        if let Pdus::Response(resp) = &decoded.data {
//            let resp_oid = &resp.0.variable_bindings[0].name;
//            let n = resp_oid.len() - 1;
//            if resp_oid[0..n] != oid_tab[0..n] {
//                break;
//            }
//            message = create_next_request(request_id, &resp_oid);
//        }
//        retval.concat(build_response(decoded, &oid, true).0);
//        request_id += 1;
//    }
//    retval
//}

///
/// Bulk get
/// This function is similar to the get function but it uses the GetBulkRequest PDU
/// to retrieve multiple values at once.
///
/// # Arguments
/// * `target` - The target IP address and port
/// * `oid` - The OID to walk
/// # Returns
/// An SnmpResult structure containing the variables
///
/// # Example
/// ```
/// use snmp_rust::r_snmp_bulk_get;
/// let result = snmp_bulk_get("127.0.0.1:161", "2c", "public", "1.3.6.1.2.1.25.3.3.1.2");
/// ```
//pub fn snmp_bulk_get(
//    target: &str,
//    _version: &str,
//    community: &str,
//    non_repeaters: u32,
//    max_repetitions: u32,
//    oid: &Vec<&str>,
//) -> SnmpResult {
//    let mut oids_tab = oid
//        .iter()
//        .map(|x| {
//            x.split('.')
//                .map(|x| x.parse::<u32>().unwrap())
//                .collect::<Vec<u32>>()
//        })
//        .collect::<Vec<Vec<u32>>>();
//
//    let mut retval = SnmpResult::new();
//    let mut request_id: i32 = 1;
//
//    let socket = UdpSocket::bind("0.0.0.0:0").unwrap();
//    socket.connect(target).expect("connect function failed");
//    let duration = std::time::Duration::from_millis(1000);
//    socket.set_read_timeout(Some(duration)).unwrap();
//
//    let variable_bindings = oids_tab
//        .iter()
//        .map(|x| VarBind {
//            name: ObjectIdentifier::new_unchecked(x.to_vec().into()),
//            value: VarBindValue::Unspecified,
//        })
//        .collect::<Vec<VarBind>>();
//
//    let pdu = BulkPdu {
//        request_id,
//        non_repeaters,
//        max_repetitions,
//        variable_bindings,
//    };
//
//    let get_request: GetBulkRequest = GetBulkRequest(pdu);
//
//    let message: Message<GetBulkRequest> = Message {
//        version: 1.into(),
//        community: community.to_string().into(),
//        data: get_request.into(),
//    };
//
//    // Send the message through an UDP socket
//    let encoded: Vec<u8> = rasn::der::encode(&message).unwrap();
//    let res: usize = socket.send(&encoded).unwrap();
//    assert!(res == encoded.len());
//
//    let mut buf: [u8; 1024] = [0; 1024];
//    let resp: (usize, std::net::SocketAddr) = socket.recv_from(buf.as_mut_slice()).unwrap();
//
//    trace!("Received {} bytes", resp.0);
//    assert!(resp.0 > 0);
//    let decoded: Message<Pdus> = rasn::ber::decode(&buf[0..resp.0]).unwrap();
//    let (result, _completed) = build_response(decoded, "", false);
//    retval.concat(result);
//    retval
//}

///
/// Bulk walk
/// This function is similar to the walk function but it uses the GetBulkRequest PDU
/// to retrieve multiple values at once.
///
/// # Arguments
/// * `target` - The target IP address and port
/// * `oid` - The OID to walk
/// # Returns
/// An SnmpResult structure containing the variables
///
/// # Example
/// ```
/// use snmp_rust::snmp_bulk_walk;
/// let result = snmp_bulk_walk("127.0.0.1:161", "2c", "public", "1.3.6.1.2.1.25.3.3.1.2");
/// ```
//pub fn snmp_bulk_walk(target: &str, _version: &str, community: &str, oid: &str) -> SnmpResult {
//    let mut oid_tab = oid
//        .split('.')
//        .map(|x| x.parse::<u32>().unwrap())
//        .collect::<Vec<u32>>();
//
//    let mut retval = SnmpResult::new_simple();
//    let mut request_id: i32 = 1;
//
//    let socket = UdpSocket::bind("0.0.0.0:0").unwrap();
//    socket.connect(target).expect("connect function failed");
//    let duration = std::time::Duration::from_millis(1000);
//    socket.set_read_timeout(Some(duration)).unwrap();
//
//    loop {
//        let variable_bindings = vec![VarBind {
//            name: ObjectIdentifier::new_unchecked(oid_tab.to_vec().into()),
//            value: VarBindValue::Unspecified,
//        }];
//
//        let pdu = BulkPdu {
//            request_id,
//            non_repeaters: 0,
//            max_repetitions: 10,
//            variable_bindings,
//        };
//
//        let get_request: GetBulkRequest = GetBulkRequest(pdu);
//
//        let message: Message<GetBulkRequest> = Message {
//            version: 1.into(),
//            community: community.to_string().into(),
//            data: get_request.into(),
//        };
//
//        // Send the message through an UDP socket
//        let encoded: Vec<u8> = rasn::der::encode(&message).unwrap();
//        let res: usize = socket.send(&encoded).unwrap();
//        assert!(res == encoded.len());
//
//        let mut buf: [u8; 1024] = [0; 1024];
//        let resp: (usize, std::net::SocketAddr) = socket.recv_from(buf.as_mut_slice()).unwrap();
//
//        trace!("Received {} bytes", resp.0);
//        assert!(resp.0 > 0);
//        let decoded: Message<Pdus> = rasn::ber::decode(&buf[0..resp.0]).unwrap();
//        if let Pdus::Response(resp) = &decoded.data {
//            let resp_oid = &resp.0.variable_bindings[0].name;
//            let n = resp_oid.len() - 1;
//        }
//        let (result, completed) = build_response(decoded, &oid, true);
//        retval.concat(result);
//        if completed {
//            break;
//        }
//        if !retval.variables.is_empty() {
//            oid_tab = retval
//                .variables
//                .last()
//                .unwrap()
//                .name
//                .split('.')
//                .map(|x| x.parse::<u32>().unwrap())
//                .collect::<Vec<u32>>();
//        }
//    }
//    retval
//}

pub fn snmp_bulk_walk_with_labels<'a>(
    target: &str,
    _version: &str,
    community: &str,
    oid: &str,
    labels: &'a BTreeMap<String, String>,
) -> SnmpResult<'a> {
    let mut oid_tab = oid
        .split('.')
        .map(|x| x.parse::<u32>().unwrap())
        .collect::<Vec<u32>>();

    let mut retval = SnmpResult::new(&labels);
    let request_id: i32 = 1;

    let socket = UdpSocket::bind("0.0.0.0:0").unwrap();
    socket.connect(target).expect("connect function failed");
    let duration = std::time::Duration::from_millis(1000);
    socket.set_read_timeout(Some(duration)).unwrap();

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
        let encoded: Vec<u8> = rasn::der::encode(&message).unwrap();
        let res: usize = socket.send(&encoded).unwrap();
        assert!(res == encoded.len());

        let mut buf: [u8; 1024] = [0; 1024];
        let resp: (usize, std::net::SocketAddr) = socket.recv_from(buf.as_mut_slice()).unwrap();

        trace!("Received {} bytes", resp.0);
        assert!(resp.0 > 0);
        let decoded: Message<Pdus> = rasn::ber::decode(&buf[0..resp.0]).unwrap();
        if let Pdus::Response(resp) = &decoded.data {
            let resp_oid = &resp.0.variable_bindings[0].name;
            let n = resp_oid.len() - 1;
            oid_tab = resp.0.variable_bindings[n - 1].name.to_string().split('.')
                .map(|x| x.parse::<u32>().unwrap())
                .collect::<Vec<u32>>();
        }
        let (result, completed) = build_response_with_labels(decoded, &oid, labels, true);
        retval.concat(result);
        if completed {
            break;
        }
    }
    retval
}

fn build_response_with_labels<'a>(
    decoded: Message<Pdus>,
    oid: &str,
    labels: &'a BTreeMap<String, String>,
    walk: bool,
) -> (SnmpResult<'a>, bool) {
    let mut retval = SnmpResult::new(labels);
    let mut completed = false;
    let mut last_oid: &str = "";

    if let Pdus::Response(resp) = &decoded.data {
        let vars = &resp.0.variable_bindings;
        for var in vars {
            let name = var.name.to_string();
            if walk {
                if !name.starts_with(oid) {
                    completed = true;
                    last_oid = "";
                    break;
                }
            }
            let mut idx: i32 = -1;
            retval.labels.iter().enumerate().for_each(|label| {
                if name.ends_with(label.1.label) {
                    idx = label.0 as i32;
                    return;
                }
            });
            if idx == -1 {
                continue;
            }
            match &var.value {
                VarBindValue::Unspecified => {
                    warn!("Unspecified");
                }
                VarBindValue::NoSuchObject => {
                    warn!("NoSuchObject");
                }
                VarBindValue::NoSuchInstance => {
                    warn!("NoSuchInstance");
                }
                VarBindValue::EndOfMibView => {
                    warn!("EndOfMibView");
                }
                VarBindValue::Value(value) => {
                    warn!("Value {:?}", &value);
                    match value {
                        rasn_smi::v2::ObjectSyntax::Simple(value) => {
                            info!("Simple {:?}", value);
                            match value {
                                rasn_smi::v2::SimpleSyntax::Integer(value) => {
                                    let v = value.try_into().unwrap();
                                    retval.add_variable(idx as usize, name, SnmpValue::Integer(v));
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                                rasn_smi::v2::SimpleSyntax::String(value) => {
                                    // We transform the value into a rust String
                                    retval.add_variable(
                                        idx as usize,
                                        name,
                                        SnmpValue::String(
                                            String::from_utf8(value.to_vec()).unwrap(),
                                        ),
                                    );
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                                rasn_smi::v2::SimpleSyntax::ObjectId(value) => {
                                    let oid: String =
                                        value.iter().map(|&id| id.to_string() + ".").collect();
                                    retval.add_variable(idx as usize, name, SnmpValue::String(oid));
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                                _ => {
                                    retval
                                        .add_variable(idx as usize, name, SnmpValue::String("Other".to_string()));
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                            };
                        }
                        rasn_smi::v2::ObjectSyntax::ApplicationWide(value) => {
                            info!("Application {:?}", value);
                        }
                    };
                }
            };
        }
    }
    (retval, completed)
}

fn build_response<'a>(
    decoded: Message<Pdus>,
    oid: &str,
    walk: bool,
) -> (SnmpResult<'a>, bool) {
    let mut retval = SnmpResult::new_simple();
    let mut completed = false;
    let mut last_oid: &str = "";

    if let Pdus::Response(resp) = &decoded.data {
        let vars = &resp.0.variable_bindings;
        for var in vars {
            let name = var.name.to_string();
            if walk {
                if !name.starts_with(oid) {
                    completed = true;
                    last_oid = "";
                    break;
                }
            }
            let mut idx: i32 = -1;
            retval.labels.iter().enumerate().for_each(|label| {
                if name.ends_with(label.1.label) {
                    idx = label.0 as i32;
                    return;
                }
            });
            if idx == -1 {
                continue;
            }
            match &var.value {
                VarBindValue::Unspecified => {
                    warn!("Unspecified");
                }
                VarBindValue::NoSuchObject => {
                    warn!("NoSuchObject");
                }
                VarBindValue::NoSuchInstance => {
                    warn!("NoSuchInstance");
                }
                VarBindValue::EndOfMibView => {
                    warn!("EndOfMibView");
                }
                VarBindValue::Value(value) => {
                    warn!("Value {:?}", &value);
                    match value {
                        rasn_smi::v2::ObjectSyntax::Simple(value) => {
                            info!("Simple {:?}", value);
                            match value {
                                rasn_smi::v2::SimpleSyntax::Integer(value) => {
                                    let v = value.try_into().unwrap();
                                    retval.add_variable(idx as usize, name, SnmpValue::Integer(v));
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                                rasn_smi::v2::SimpleSyntax::String(value) => {
                                    // We transform the value into a rust String
                                    retval.add_variable(idx as usize,
                                        name,
                                        SnmpValue::String(
                                            String::from_utf8(value.to_vec()).unwrap(),
                                        ),
                                    );
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                                rasn_smi::v2::SimpleSyntax::ObjectId(value) => {
                                    let oid: String =
                                        value.iter().map(|&id| id.to_string() + ".").collect();
                                    retval.add_variable(idx as usize, name, SnmpValue::String(oid));
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                                _ => {
                                    retval
                                        .add_variable(idx as usize, name, SnmpValue::String("Other".to_string()));
                                    last_oid = retval.get_last_oid(idx as usize);
                                }
                            };
                        }
                        rasn_smi::v2::ObjectSyntax::ApplicationWide(value) => {
                            info!("Application {:?}", value);
                        }
                    };
                }
            };
        }
    }
    (retval, completed)
}
//mod tests {
//    use super::*;
//
//    #[test]
//    fn test_snmp_get() {
//        let result = r_snmp_get("127.0.0.1:161", "1.3.6.1.2.1.1.1.0", "public");
//        let expected = SnmpResult {
//            variables: vec![SnmpVariable::new(
//                "1.3.6.1.2.1.1.1.0".to_string(),
//                "Linux CNTR-PORT-A104 6.1.0-31-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.128-1 (2025-02-07) x86_64".to_string())],
//        };
//        assert_eq!(result, expected);
//    }
//
//    #[test]
//    fn test_snmp_walk() {
//        let result = r_snmp_walk("127.0.0.1:161", "1.3.6.1.2.1.25.3.3.1.2");
//
//        let re = Regex::new(r"[0-9]+").unwrap();
//        assert!(result.variables.len() > 0);
//        for v in result.variables.iter() {
//            let name = &v.name;
//            assert!(name.starts_with("1.3.6.1.2.1.25.3.3.1.2"));
//            assert!(re.is_match(&v.value));
//        }
//    }
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
//}
