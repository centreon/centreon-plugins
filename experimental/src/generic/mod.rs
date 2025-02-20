extern crate serde;
extern crate serde_json;

use lib::{r_snmp_bulk_walk, SnmpResult};
use serde::Deserialize;

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
struct Leaf {
    name: String,
    output: String,
    entries: Vec<Entry>,
    data: Option<Data>,
}

#[derive(Deserialize, Debug)]
pub struct Command {
    leaf: Leaf,
}

pub struct CmdResult {
    pub status: i32,
    pub output: String,
}

pub struct CommandExt {
    pub warning_core: Option<String>,
    pub critical_core: Option<String>,
    pub warning_agregation: Option<String>,
    pub critical_agregation: Option<String>,
}

fn compute_status(value: f32, warn: &Option<String>, crit: &Option<String>) -> i32 {
    if let Some(c) = crit {
        let crit = c.parse().unwrap();
        if value > crit {
            return 2;
        }
    }
    if let Some(w) = warn {
        let warn = w.parse().unwrap();
        if value > warn {
            return 1;
        }
    }
    0
}

fn build_status(metrics: &Vec<(String, f32, i32)>) -> i32 {
    let mut retval = 0;
    metrics.iter().for_each(|(_, _, s)| {
        if *s > retval {
            retval = *s;
            if retval == 2 {
                return;
            }
        }
    });
    return retval;
}

fn build_metrics<'a>(
    values: &Vec<(String, f32)>,
    ag: &Option<(&str, usize, f32)>,
    ext: &'a CommandExt,
) -> (
    Vec<(String, f32, &'a Option<String>, &'a Option<String>)>,
    i32,
) {
    let mut metrics: Vec<(String, f32, &Option<String>, &Option<String>)> = Vec::new();
    let mut status = 0;
    match ag {
        Some(a) => {
            // The agregation is located in first place
            if a.1 == 0 {
                let w = &ext.warning_agregation;
                let c = &ext.critical_agregation;
                let current_status =
                    compute_status(a.2, &ext.warning_agregation, &ext.critical_agregation);
                metrics.push((a.0.to_string(), a.2, w, c));
                if current_status > status {
                    status = current_status;
                }
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
        ));
        if current_status > status {
            status = current_status;
        }
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
                ));
                if current_status > status {
                    status = current_status;
                }
            }
        }
        None => (),
    }
    (metrics, status)
}

impl Command {
    pub fn execute(&self, target: &str, ext: &CommandExt) -> CmdResult {
        let mut agregation = ("", 0, Operation::None);
        let mut res: Option<(&str, SnmpResult)> = None;
        for (idx, entry) in self.leaf.entries.iter().enumerate() {
            match entry {
                Entry::Agregation(op) => {
                    agregation = (&op.name, idx, op.op);
                }
                Entry::Query(query) => match query.query {
                    QueryType::Walk => {
                        res = Some((&query.name, r_snmp_bulk_walk(target, &query.oid)));
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
                    status: 3,
                    output: "No result".to_string(),
                };
            }
        }
    }

    fn build_output(
        &self,
        count: usize,
        status: i32,
        metrics: &Vec<(String, f32, &Option<String>, &Option<String>)>,
        ag: &Option<(&str, usize, f32)>,
        ext: &CommandExt,
    ) -> String {
        let mut retval = self
            .leaf
            .output
            .replace("{count}", count.to_string().as_str())
            .replace(
                "{status}",
                match status {
                    0 => "OK",
                    1 => "WARNING",
                    2 => "CRITICAL",
                    _ => "UNKNOWN",
                },
            );
        match ag {
            Some(a) => {
                retval = retval.replace(format!("{{{}}}", a.0).as_str(), a.2.to_string().as_str());
            }
            None => (),
        };
        retval += " |";
        match &self.leaf.data {
            Some(d) => {
                metrics.iter().for_each(|(k, v, w, c)| {
                    retval += format!(
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
                metrics.iter().for_each(|(k, v, w, c)| {
                    retval += format!(
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
        retval
    }
}
