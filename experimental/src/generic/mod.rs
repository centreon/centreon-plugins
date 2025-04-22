extern crate serde;
extern crate serde_json;

use compute::{Compute, Parser};
use serde::Deserialize;
use snmp::{snmp_bulk_get, snmp_bulk_walk, snmp_bulk_walk_with_labels};
use std::collections::HashMap;

#[derive(Copy, Clone, PartialEq)]
pub enum Status {
    Ok = 0,
    Warning = 1,
    Critical = 2,
    Unknown = 3,
}

impl Status {
    fn as_str(&self) -> &str {
        match *self {
            Status::Ok => "OK",
            Status::Warning => "WARNING",
            Status::Critical => "CRITICAL",
            Status::Unknown => "UNKNOWN",
        }
    }
}

fn worst(a: Status, b: Status) -> Status {
    let a_int = match a {
        Status::Ok => 0,
        Status::Warning => 1,
        Status::Critical => 3,
        Status::Unknown => 2,
    };
    let b_int = match b {
        Status::Ok => 0,
        Status::Warning => 1,
        Status::Critical => 3,
        Status::Unknown => 2,
    };
    if a_int > b_int {
        return a;
    } else {
        return b;
    }
}

#[derive(Deserialize, Debug)]
enum QueryType {
    Get,
    Walk,
}

#[derive(Deserialize, Debug)]
pub struct Snmp {
    name: String,
    oid: String,
    query: QueryType,
    labels: Option<HashMap<String, String>>,
}

#[derive(Deserialize, Debug)]
pub struct Collect {
    snmp: Vec<Snmp>,
}

#[derive(Deserialize, Debug)]
pub struct Command {
    collect: Collect,
    compute: Compute,
}

pub struct CmdResult {
    pub status: Status,
    pub output: String,
}

pub struct CommandExt {
    pub warning_core: Option<String>,
    pub critical_core: Option<String>,
    pub warning_agregation: Option<String>,
    pub critical_agregation: Option<String>,
}

fn compute_status(value: f64, warn: &Option<String>, crit: &Option<String>) -> Status {
    if let Some(c) = crit {
        let crit = c.parse().unwrap();
        if value > crit {
            return Status::Critical;
        }
    }
    if let Some(w) = warn {
        let warn = w.parse().unwrap();
        if value > warn {
            return Status::Warning;
        }
    }
    Status::Ok
}

impl Command {
    pub fn execute(
        &self,
        target: &str,
        version: &str,
        community: &str,
        //ext: &CommandExt,
    ) -> CmdResult {
        let mut to_get = Vec::new();
        let mut get_name = Vec::new();
        let mut collect = Vec::new();

        for s in self.collect.snmp.iter() {
            match s.query {
                QueryType::Walk => {
                    if let Some(lab) = &s.labels {
                        let r = snmp_bulk_walk_with_labels(
                            target, version, community, &s.oid, &s.name, &lab,
                        );
                        collect.push(r);
                    } else {
                        let r = snmp_bulk_walk(target, version, community, &s.oid, &s.name);
                        collect.push(r);
                    }
                }
                QueryType::Get => {
                    to_get.push(s.oid.as_str());
                    get_name.push(s.name.as_str());
                }
            }
        }

        if !to_get.is_empty() {
            let r = snmp_bulk_get(target, version, community, 1, 1, &to_get, &get_name);
            collect.push(r);
        }
        println!("{:#?}", collect);

        for (i, metric) in self.compute.metrics.iter().enumerate() {
            let name = match &metric.prefix {
                Some(prefix) => {
                    format!("{:?}#{}", prefix, metric.name)
                }

                None => format!("{}#{}", i, metric.name),
            };
            println!("name: {}", name);
            let value = &metric.value;
            println!("value: {}", value);
            let parser = Parser::new(&collect);
            let value = parser.eval(value).unwrap();
            println!("value result: {:?}", value);
        }

        CmdResult {
            status: Status::Unknown,
            output: "No result".to_string(),
        }
    }
}
