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

struct Metric<'b> {
    name: String,
    value: f32,
    warning: &'b Option<String>,
    critical: &'b Option<String>,
    status: Status,
    agregated: bool,
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
struct OutputTable {
    header: String,
    text: Vec<String>,
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
) -> (Vec<Metric<'a>>, Status) {
    let mut metrics: Vec<Metric> = Vec::new();
    let mut status = Status::Ok;
    match ag {
        Some(a) => {
            // The agregation is located in first place
            if a.1 == 0 {
                let w = &ext.warning_agregation;
                let c = &ext.critical_agregation;
                let current_status =
                    compute_status(a.2, &ext.warning_agregation, &ext.critical_agregation);
                metrics.push(Metric {
                    name: a.0.to_string(),
                    value: a.2,
                    warning: w,
                    critical: c,
                    status: current_status,
                    agregated: true,
                });
                status = worst(current_status, status);
            }
        }
        None => (),
    }
    values.iter().enumerate().for_each(|(i, v)| {
        let current_status = compute_status(v.1, &ext.warning_core, &ext.critical_core);
        metrics.push(Metric {
            name: values[i].0.clone(),
            value: v.1,
            warning: &ext.warning_core,
            critical: &ext.critical_core,
            status: current_status,
            agregated: false,
        });
        status = worst(current_status, status);
    });
    match ag {
        Some(a) => {
            if a.1 > 0 {
                let current_status =
                    compute_status(a.2, &ext.warning_agregation, &ext.critical_agregation);
                metrics.push(Metric {
                    name: a.0.to_string(),
                    value: a.2,
                    warning: &ext.warning_agregation,
                    critical: &ext.critical_agregation,
                    status: current_status,
                    agregated: true,
                });
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
        metrics: &Vec<Metric>,
        ag: &Option<(&str, usize, f32)>,
        ext: &CommandExt,
    ) -> String {
        let no_threshold = ext.warning_core.is_none()
            && ext.critical_core.is_none()
            && ext.warning_agregation.is_none()
            && ext.critical_agregation.is_none();
        let write_details =
            no_threshold || (ext.warning_core.is_some() || ext.critical_core.is_some());
        let write_agregation_details =
            no_threshold || (ext.warning_agregation.is_some() || ext.critical_agregation.is_some());
        let mut output_text = "".to_string();
        let mut begun = false;
        if &self.leaf.output.header != "" {
            output_text = self.leaf.output.header.replace("{status}", status.as_str());
        }
        for line in &self.leaf.output.text {
            if line.contains("idx") {
                if write_details {
                    // We have to iterate on metrics
                    let mut output_vec = (Vec::new(), Vec::new(), Vec::new());
                    let mut idx = 0;
                    for m in metrics.iter() {
                        if !m.agregated {
                            let text = line
                                .replace("{idx}", idx.to_string().as_str())
                                .replace("{name}", m.name.as_str())
                                .replace("{value}", format!("{:.2}", m.value).as_str())
                                .replace("{count}", count.to_string().as_str());
                            match m.status {
                                Status::Ok => {
                                    output_vec.0.push(text);
                                }
                                Status::Warning => {
                                    output_vec.1.push(text);
                                }
                                Status::Critical => {
                                    output_vec.2.push(text);
                                }
                                Status::Unknown => (),
                            }
                            idx += 1;
                        }
                    }
                    if !output_vec.2.is_empty() {
                        if begun {
                            output_text += " - ";
                        } else {
                            begun = true;
                        }
                        output_text += output_vec.2.join(" - ").as_str();
                    }
                    if !output_vec.1.is_empty() {
                        if begun {
                            output_text += " - ";
                        } else {
                            begun = true;
                        }
                        output_text += output_vec.1.join(" - ").as_str();
                    }
                    if !output_vec.0.is_empty() {
                        if begun {
                            output_text += " - ";
                        }
                        output_text += output_vec.0.join(" - ").as_str();
                    }
                }
            } else {
                if write_agregation_details {
                    match ag {
                        Some(a) => {
                            output_text += line
                                .replace(
                                    format!("{{{}}}", a.0).as_str(),
                                    format!("{:.2}", a.2).as_str(),
                                )
                                .replace("{count}", count.to_string().as_str())
                                .as_str();
                            begun = true;
                        }
                        None => output_text += line,
                    };
                }
            }
        }

        let mut perfdata = " |".to_string();
        match &self.leaf.data {
            Some(d) => {
                metrics.iter().for_each(|m| {
                    perfdata += format!(
                        " '{}'={}{};{};{};{};{}",
                        m.name,
                        m.value,
                        d.uom,
                        match m.warning {
                            Some(m) => m.to_string(),
                            None => "".to_string(),
                        },
                        match m.critical {
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
                metrics.iter().for_each(|m| {
                    perfdata += format!(
                        " '{}'={};{};{}",
                        m.name,
                        m.value,
                        match m.warning {
                            Some(v) => v.to_string(),
                            None => "".to_string(),
                        },
                        match m.critical {
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
