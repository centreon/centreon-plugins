extern crate serde;
extern crate serde_json;

use lib::{r_snmp_bulk_walk, SnmpResult};
use serde::Deserialize;

#[derive(Copy, Clone, PartialEq)]
pub enum Status {
    Ok = 0,
    Warning = 1,
    Critical = 2,
    Unknown = 3,
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

#[derive(Deserialize, Debug, Clone, Copy)]
enum Operation {
    None,
    Average,
}

#[derive(Deserialize, Debug)]
enum QueryType {
    Walk,
}

#[derive(Deserialize, Debug)]
struct EntryOperation {
    name: String,
    op: Operation,
}

#[derive(Deserialize, Debug)]
struct EntryQuery {
    name: String,
    oid: String,
    query: QueryType,
}

#[derive(Deserialize, Debug)]
enum Entry {
    Agregation(EntryOperation),
    Query(EntryQuery),
}

#[derive(Deserialize, Debug)]
struct Data {
    uom: String,
    min: Option<f32>,
    max: Option<f32>,
}

#[derive(Deserialize, Debug)]
struct StatusText {
    header: String,
    text: String,
}

#[derive(Deserialize, Debug)]
struct OutputTable {
    default: String,
    status: Option<StatusText>,
}

#[derive(Deserialize, Debug)]
struct Leaf {
    name: String,
    output: OutputTable,
    entries: Vec<Entry>,
    data: Option<Data>,
}

#[derive(Deserialize, Debug)]
pub struct Command {
    leaf: Leaf,
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

fn compute_status(value: f32, warn: &Option<String>, crit: &Option<String>) -> Status {
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

fn build_metrics<'a>(
    values: &Vec<(String, f32)>,
    ag: &Option<(&str, usize, f32)>,
    ext: &'a CommandExt,
) -> (
    Vec<(String, f32, &'a Option<String>, &'a Option<String>, Status)>,
    Status,
) {
    let mut metrics: Vec<(String, f32, &Option<String>, &Option<String>, Status)> = Vec::new();
    let mut status = Status::Ok;
    match ag {
        Some(a) => {
            // The agregation is located in first place
            if a.1 == 0 {
                let w = &ext.warning_agregation;
                let c = &ext.critical_agregation;
                let current_status =
                    compute_status(a.2, &ext.warning_agregation, &ext.critical_agregation);
                metrics.push((a.0.to_string(), a.2, w, c, current_status));
                status = worst(current_status, status);
            }
        }
        None => (),
    }
    values.iter().enumerate().for_each(|(i, v)| {
        let current_status = compute_status(v.1, &ext.warning_core, &ext.critical_core);
        metrics.push((
            values[i].0.clone(),
            v.1,
            &ext.warning_core,
            &ext.critical_core,
            current_status,
        ));
        status = worst(current_status, status);
    });
    match ag {
        Some(a) => {
            if a.1 > 0 {
                let current_status =
                    compute_status(a.2, &ext.warning_agregation, &ext.critical_agregation);
                metrics.push((
                    a.0.to_string(),
                    a.2,
                    &ext.warning_agregation,
                    &ext.critical_agregation,
                    current_status,
                ));
                status = worst(current_status, status);
            }
        }
        None => (),
    }
    (metrics, status)
}

impl Command {
    pub fn execute(
        &self,
        target: &str,
        version: &str,
        community: &str,
        ext: &CommandExt,
    ) -> CmdResult {
        let mut agregation = ("", 0, Operation::None);
        let mut res: Option<(&str, SnmpResult)> = None;
        for (idx, entry) in self.leaf.entries.iter().enumerate() {
            match entry {
                Entry::Agregation(op) => {
                    agregation = (&op.name, idx, op.op);
                }
                Entry::Query(query) => match query.query {
                    QueryType::Walk => {
                        res = Some((
                            &query.name,
                            r_snmp_bulk_walk(target, version, community, &query.oid),
                        ));
                    }
                },
            }
        }
        match res {
            Some(r) => {
                let mut values: Vec<(String, f32)> = Vec::new();
                let mut idx = 0;
                r.1.variables.iter().for_each(|v| {
                    let label = r.0.replace("{idx}", &idx.to_string());
                    values.push((label, v.value.parse().unwrap()));
                    idx += 1;
                });
                let count = values.len();
                let ag = match agregation.2 {
                    Operation::Average => {
                        let sum: f32 = values.iter().map(|(_, v)| v).sum();
                        let avg = sum / values.len() as f32;
                        Some((agregation.0, agregation.1, avg))
                    }
                    _ => None,
                };
                let (metrics, status) = build_metrics(&values, &ag, &ext);
                let output = self.build_output(count, status, &metrics, &ag, &ext);
                return CmdResult { status, output };
            }
            None => {
                return CmdResult {
                    status: Status::Unknown,
                    output: "No result".to_string(),
                };
            }
        }
    }

    fn build_output(
        &self,
        count: usize,
        status: Status,
        metrics: &Vec<(String, f32, &Option<String>, &Option<String>, Status)>,
        ag: &Option<(&str, usize, f32)>,
        ext: &CommandExt,
    ) -> String {
        let mut output_text: String;
        if status == Status::Ok {
            output_text = self
                .leaf
                .output
                .default
                .replace("{count}", count.to_string().as_str())
                .replace(
                    "{status}",
                    match status {
                        Status::Ok => "OK",
                        Status::Warning => "WARNING",
                        Status::Critical => "CRITICAL",
                        Status::Unknown => "UNKNOWN",
                    },
                );
            match ag {
                Some(a) => {
                    output_text = output_text
                        .replace(format!("{{{}}}", a.0).as_str(), a.2.to_string().as_str());
                }
                None => (),
            };
        } else {
            let mut warning_array = Vec::new();
            let mut critical_array = Vec::new();
            let part = &self.leaf.output.status;
            for (idx, m) in metrics.iter().enumerate() {
                if m.4 == Status::Warning {
                    let output_str = match *part {
                        Some(ref s) => {
                            s.text.replace("{value}", m.1.to_string().as_str())
                                .replace("{idx}", idx.to_string().as_str())
                        }
                        None => "".to_string(),
                    };
                    warning_array.push(output_str);
                } else if m.4 == Status::Critical {
                    let part = &self.leaf.output.status;
                    let output_str = match *part {
                        Some(ref s) => {
                            s.text.replace("{value}", m.1.to_string().as_str())
                                .replace("{idx}", idx.to_string().as_str())
                        }
                        None => "".to_string(),
                    };
                    critical_array.push(output_str);
                }
            }
            let warn_header = match *part {
                Some(ref s) => &s.header.replace("{status}", "WARNING"),
                None => "",
            };
            let crit_header = match *part {
                Some(ref s) => &s.header.replace("{status}", "CRITICAL"),
                None => "",
            };
            if !warning_array.is_empty() && !critical_array.is_empty() {
                output_text = format!("{} {} - {} {}", crit_header, &critical_array.join(" - "), warn_header, &warning_array.join(" - "));
            } else if !warning_array.is_empty() {
                output_text = format!("{} {}", warn_header, &warning_array.join(" - "));
            } else {
                output_text = format!("{} {}", crit_header, critical_array.join(" - "));
            }
        }

        let mut perfdata = " |".to_string();
        match &self.leaf.data {
            Some(d) => {
                metrics.iter().for_each(|(k, v, w, c, s)| {
                    perfdata += format!(
                        " {}={}{};{};{};{};{}",
                        k,
                        v,
                        d.uom,
                        match w {
                            Some(m) => m.to_string(),
                            None => "".to_string(),
                        },
                        match c {
                            Some(m) => m.to_string(),
                            None => "".to_string(),
                        },
                        match d.min {
                            Some(m) => m.to_string(),
                            None => "".to_string(),
                        },
                        match d.max {
                            Some(m) => m.to_string(),
                            None => "".to_string(),
                        },
                    )
                    .as_str();
                });
            }
            None => {
                metrics.iter().for_each(|(k, v, w, c, s)| {
                    perfdata += format!(
                        " {}={};{};{}",
                        k,
                        v,
                        match w {
                            Some(v) => v.to_string(),
                            None => "".to_string(),
                        },
                        match c {
                            Some(v) => v.to_string(),
                            None => "".to_string(),
                        }
                    )
                    .as_str();
                });
            }
        };
        output_text + &perfdata
    }
}
