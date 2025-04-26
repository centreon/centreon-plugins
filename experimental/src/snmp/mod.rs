extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;

use compute::ast::ExprResult;
use log::{info, trace, warn};
use rasn::types::ObjectIdentifier;
use rasn_snmp::v2::BulkPdu;
use rasn_snmp::v2::Pdus;
use rasn_snmp::v2::VarBind;
use rasn_snmp::v2::VarBindValue;
use rasn_snmp::v2::{GetBulkRequest, GetNextRequest, GetRequest};
use rasn_snmp::v2c::Message;
use std::collections::HashMap;
use std::convert::TryInto;
use std::net::UdpSocket;

pub enum ValueType {
    None(()),
    Integer(i64),
    Float(f64),
    String(String),
}

#[derive(Debug)]
pub struct SnmpResult {
    pub items: HashMap<String, ExprResult>,
    last_oid: Vec<u32>,
}

impl SnmpResult {
    pub fn new(items: HashMap<String, ExprResult>) -> SnmpResult {
        SnmpResult {
            items,
            last_oid: Vec::new(),
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
//        retval.merge(build_response(decoded, &oid, true).0);
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
pub fn snmp_bulk_get<'a>(
    target: &str,
    _version: &str,
    community: &str,
    non_repeaters: u32,
    max_repetitions: u32,
    oid: &Vec<&str>,
    names: &Vec<&str>,
) -> SnmpResult {
    let mut oids_tab = oid
        .iter()
        .map(|x| {
            x.split('.')
                .map(|x| x.parse::<u32>().unwrap())
                .collect::<Vec<u32>>()
        })
        .collect::<Vec<Vec<u32>>>();

    let mut retval = SnmpResult {
        items: HashMap::new(),
        last_oid: Vec::new(),
    };
    let mut request_id: i32 = 1;

    let socket = UdpSocket::bind("0.0.0.0:0").unwrap();
    socket.connect(target).expect("connect function failed");
    let duration = std::time::Duration::from_millis(1000);
    socket.set_read_timeout(Some(duration)).unwrap();

    let variable_bindings = oids_tab
        .iter()
        .map(|x| VarBind {
            name: ObjectIdentifier::new_unchecked(x.to_vec().into()),
            value: VarBindValue::Unspecified,
        })
        .collect::<Vec<VarBind>>();

    let pdu = BulkPdu {
        request_id,
        non_repeaters,
        max_repetitions,
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
    let _completed = retval.build_response_with_names(decoded, "", names, false);
    retval
}

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
pub fn snmp_bulk_walk<'a>(
    target: &str,
    _version: &str,
    community: &str,
    oid: &str,
    snmp_name: &str,
) -> SnmpResult {
    let oid_init = oid
        .split('.')
        .map(|x| x.parse::<u32>().unwrap())
        .collect::<Vec<u32>>();
    let mut oid_tab = &oid_init;
    let mut retval = SnmpResult {
        items: HashMap::new(),
        last_oid: Vec::new(),
    };
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
        let completed = retval.build_response(decoded, &oid, snmp_name, true);

        if completed {
            break;
        }
        oid_tab = &retval.last_oid;
    }
    retval
}

pub fn snmp_bulk_walk_with_labels<'a>(
    target: &str,
    _version: &str,
    community: &str,
    oid: &str,
    snmp_name: &str,
    labels: &'a HashMap<String, String>,
) -> SnmpResult {
    let oid_init = oid
        .split('.')
        .map(|x| x.parse::<u32>().unwrap())
        .collect::<Vec<u32>>();

    let mut oid_tab = &oid_init;
    let mut retval = SnmpResult {
        items: HashMap::new(),
        last_oid: Vec::new(),
    };
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
        let completed = retval.build_response_with_labels(decoded, &oid, snmp_name, labels, true);
        if completed {
            break;
        }
        oid_tab = &retval.last_oid;
    }
    retval
}

impl SnmpResult {
    fn build_response_with_labels<'a>(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        snmp_name: &str,
        labels: &'a HashMap<String, String>,
        walk: bool,
    ) -> bool {
        let mut completed = false;

        if let Pdus::Response(resp) = &decoded.data {
            let vars = &resp.0.variable_bindings;
            for var in vars {
                let name = var.name.to_string();
                self.last_oid = name
                    .split('.')
                    .map(|x| x.parse::<u32>().unwrap())
                    .collect::<Vec<u32>>();
                if walk {
                    if !name.starts_with(oid) {
                        completed = true;
                        break;
                    }
                }
                let prefix = &name[..name.rfind('.').unwrap()];
                for l in labels {
                    if prefix.ends_with(l.0) {
                        let mut typ = ValueType::None(());
                        let value = match &var.value {
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
                                                typ = ValueType::Integer(value.try_into().unwrap());
                                            }
                                            rasn_smi::v2::SimpleSyntax::String(value) => {
                                                // We transform the value into a rust String
                                                typ = ValueType::String(
                                                    String::from_utf8(value.to_vec()).unwrap(),
                                                );
                                            }
                                            rasn_smi::v2::SimpleSyntax::ObjectId(value) => {
                                                let oid: String = value
                                                    .iter()
                                                    .map(|&id| id.to_string() + ".")
                                                    .collect();
                                                typ = ValueType::String(oid);
                                            }
                                            _ => {
                                                typ = ValueType::String("Other".to_string());
                                            }
                                        };
                                    }
                                    rasn_smi::v2::ObjectSyntax::ApplicationWide(value) => {
                                        info!("Application {:?}", value);
                                    }
                                };
                            }
                        };
                        let key = format!("{}.{}", snmp_name, l.1);
                        self.items
                            .entry(key)
                            .and_modify(|e| match e {
                                ExprResult::Scalar(_) => panic!("Should not arrive"),
                                ExprResult::Vector(v) => v.push(match &typ {
                                    ValueType::Float(f) => *f,
                                    ValueType::None(()) => {
                                        panic!("Should not arrive");
                                    }
                                    ValueType::String(_) => {
                                        panic!("Value should be a float");
                                    }
                                    ValueType::Integer(i) => *i as f64,
                                }),
                                ExprResult::StrVector(v) => v.push(match &typ {
                                    ValueType::Float(_) => {
                                        panic!("Value should be a string");
                                    }
                                    ValueType::None(()) => {
                                        panic!("Should not arrive");
                                    }
                                    ValueType::String(s) => s.to_string(),
                                    ValueType::Integer(_) => {
                                        panic!("Value should be a string");
                                    }
                                }),
                            })
                            .or_insert(match typ {
                                ValueType::Float(f) => ExprResult::Vector(vec![f]),
                                ValueType::None(()) => {
                                    panic!("Should not arrive");
                                }
                                ValueType::String(s) => ExprResult::StrVector(vec![s]),
                                ValueType::Integer(i) => ExprResult::Vector(vec![i as f64]),
                            });
                    }
                }
            }
        }
        completed
    }

    fn build_response_with_names<'a>(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        names: &Vec<&str>,
        walk: bool,
    ) -> bool {
        let mut completed = false;

        if let Pdus::Response(resp) = &decoded.data {
            let vars = &resp.0.variable_bindings;
            for (idx, var) in vars.iter().enumerate() {
                let name = var.name.to_string();
                self.last_oid = name
                    .split('.')
                    .map(|x| x.parse::<u32>().unwrap())
                    .collect::<Vec<u32>>();
                if walk {
                    if !name.starts_with(oid) {
                        completed = true;
                        break;
                    }
                }
                let prefix: &str = &name[..name.rfind('.').unwrap()];
                let mut typ = ValueType::None(());
                let value = match &var.value {
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
                                        typ = ValueType::Integer(value.try_into().unwrap());
                                    }
                                    rasn_smi::v2::SimpleSyntax::String(value) => {
                                        // We transform the value into a rust String
                                        typ = ValueType::String(
                                            String::from_utf8(value.to_vec()).unwrap(),
                                        );
                                    }
                                    rasn_smi::v2::SimpleSyntax::ObjectId(value) => {
                                        let oid: String =
                                            value.iter().map(|&id| id.to_string() + ".").collect();
                                        typ = ValueType::String(oid);
                                    }
                                    _ => {
                                        typ = ValueType::String("Other".to_string());
                                    }
                                }
                            }
                            _ => {
                                info!("other");
                            }
                        }
                    }
                };
                let key = format!("{}", names[idx]);
                self.items
                    .entry(key)
                    .and_modify(|e| match e {
                        ExprResult::Scalar(_) => panic!("Should not arrive"),
                        ExprResult::Vector(v) => v.push(match &typ {
                            ValueType::Float(f) => *f,
                            ValueType::None(()) => {
                                panic!("Should not arrive");
                            }
                            ValueType::String(_) => {
                                panic!("Value should be a float");
                            }
                            ValueType::Integer(i) => *i as f64,
                        }),
                        ExprResult::StrVector(v) => v.push(match &typ {
                            ValueType::Float(_) => {
                                panic!("Value should be a string");
                            }
                            ValueType::None(()) => {
                                panic!("Should not arrive");
                            }
                            ValueType::String(s) => s.to_string(),
                            ValueType::Integer(_) => {
                                panic!("Value should be a string");
                            }
                        }),
                    })
                    .or_insert(match typ {
                        ValueType::Float(f) => ExprResult::Vector(vec![f]),
                        ValueType::None(()) => {
                            panic!("Should not arrive");
                        }
                        ValueType::String(s) => ExprResult::StrVector(vec![s]),
                        ValueType::Integer(i) => ExprResult::Vector(vec![i as f64]),
                    });
            }
        }
        completed
    }
    fn build_response<'a>(
        &mut self,
        decoded: Message<Pdus>,
        oid: &str,
        snmp_name: &str,
        walk: bool,
    ) -> bool {
        let mut completed = false;

        if let Pdus::Response(resp) = &decoded.data {
            let vars = &resp.0.variable_bindings;
            for var in vars {
                let name = var.name.to_string();
                self.last_oid = name
                    .split('.')
                    .map(|x| x.parse::<u32>().unwrap())
                    .collect::<Vec<u32>>();
                if walk {
                    if !name.starts_with(oid) {
                        completed = true;
                        break;
                    }
                }
                let prefix: &str = &name[..name.rfind('.').unwrap()];
                let mut typ = ValueType::None(());
                let value = match &var.value {
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
                                        typ = ValueType::Integer(value.try_into().unwrap());
                                    }
                                    rasn_smi::v2::SimpleSyntax::String(value) => {
                                        // We transform the value into a rust String
                                        typ = ValueType::String(
                                            String::from_utf8(value.to_vec()).unwrap(),
                                        );
                                    }
                                    rasn_smi::v2::SimpleSyntax::ObjectId(value) => {
                                        let oid: String =
                                            value.iter().map(|&id| id.to_string() + ".").collect();
                                        typ = ValueType::String(oid);
                                    }
                                    _ => {
                                        typ = ValueType::String("Other".to_string());
                                    }
                                }
                            }
                            _ => {
                                info!("other");
                            }
                        }
                        //match value {
                        //    rasn_smi::v2::ObjectSyntax::Simple(value) => {
                        //        info!("Simple {:?}", value);
                        //        match value {
                        //            rasn_smi::v2::ObjectSyntax::Simple(value) => {
                        //                info!("Simple {:?}", value);
                        //                match value {
                        //                    rasn_smi::v2::SimpleSyntax::Integer(value) => {
                        //                        typ = ValueType::Integer(value.try_into().unwrap());
                        //                    }
                        //                    rasn_smi::v2::SimpleSyntax::String(value) => {
                        //                        // We transform the value into a rust String
                        //                        typ = ValueType::String(
                        //                            String::from_utf8(value.to_vec()).unwrap(),
                        //                        );
                        //                    }
                        //                    rasn_smi::v2::SimpleSyntax::ObjectId(value) => {
                        //                        let oid: String = value
                        //                            .iter()
                        //                            .map(|&id| id.to_string() + ".")
                        //                            .collect();
                        //                        typ = ValueType::String(oid);
                        //                    }
                        //                    _ => {
                        //                        typ = ValueType::String("Other".to_string());
                        //                    }
                        //                };
                        //            }
                        //            rasn_smi::v2::ObjectSyntax::ApplicationWide(value) => {
                        //                info!("Application {:?}", value);
                        //            }
                        //        };
                        //    }
                        //}
                    }
                };
                let key = format!("{}", snmp_name);
                self.items
                    .entry(key)
                    .and_modify(|e| match e {
                        ExprResult::Scalar(_) => panic!("Should not arrive"),
                        ExprResult::Vector(v) => v.push(match &typ {
                            ValueType::Float(f) => *f,
                            ValueType::None(()) => {
                                panic!("Should not arrive");
                            }
                            ValueType::String(_) => {
                                panic!("Value should be a float");
                            }
                            ValueType::Integer(i) => *i as f64,
                        }),
                        ExprResult::StrVector(v) => v.push(match &typ {
                            ValueType::Float(_) => {
                                panic!("Value should be a string");
                            }
                            ValueType::None(()) => {
                                panic!("Should not arrive");
                            }
                            ValueType::String(s) => s.to_string(),
                            ValueType::Integer(_) => {
                                panic!("Value should be a string");
                            }
                        }),
                    })
                    .or_insert(match typ {
                        ValueType::Float(f) => ExprResult::Vector(vec![f]),
                        ValueType::None(()) => {
                            panic!("Should not arrive");
                        }
                        ValueType::String(s) => ExprResult::StrVector(vec![s]),
                        ValueType::Integer(i) => ExprResult::Vector(vec![i as f64]),
                    });
            }
        }
        completed
    }
}

//mod tests {
//    use super::*;
//
//    #[test]
//    fn test_snmp_get() {
//        let result = r_snmp_get("127.0.0.1:161", "1.3.6.1.2.1.1.1.0", "public");
//        let expected = SnmpResult {
//            variables: vec![SnmpVariable{
//                "1.3.6.1.2.1.1.1.0".to_string(),
//                "Linux CNTR-PORT-A104 6.1.0-31-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.128-1 (2025-02-07) x86_64".to_string()}],
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
