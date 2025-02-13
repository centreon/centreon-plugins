extern crate serde;
extern crate serde_json;

use serde::Deserialize;
use std::collections::{BTreeMap, HashMap};
use lib::{r_snmp_walk, SnmpResult};

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
struct Leaf {
    name: String,
    output: String,
    entries: Vec<Entry>,
}

#[derive(Deserialize, Debug)]
pub struct Command {
  leaf: Leaf,
}

pub struct CmdResult {

}

impl Command {
    pub fn execute(&self, target: &str) -> CmdResult {
        let mut agregation = ("", Operation::None);
        let mut res: Option<(&str, SnmpResult)> = None;
        for entry in &self.leaf.entries {
            match entry {
                Entry::Agregation(op) => {
                    println!("Agregation: {:?}", op);
                    agregation = (&op.name, op.op);
                },
                Entry::Query(query) => {
                    match query.query {
                        QueryType::Walk => {
                            res = Some((&query.name, r_snmp_walk(target, &query.oid)));
                        }
                    }
                }
            }
        }
        match res {
            Some(r) => {
                let mut values: Vec<f32> = Vec::new();
                let mut labels: Vec<String> = Vec::new();
                let mut idx = 0;
                r.1.variables.iter().for_each(|v| {
                    values.push(v.value.parse().unwrap());
                    let label = r.0.replace("{idx}", &idx.to_string());
                    labels.push(label);
                    idx += 1;
                });
                let count = values.len();
                let ag = match agregation.1 {
                    Operation::Average => {
                        let sum: f32 = values.iter().sum();
                        Some((agregation.0, sum / values.len() as f32))
                    },
                    _ => None,
                };
                let metrics = self.build_metrics(&labels, &values, ag);
                println!("Metrics: {:?}", metrics);
            },
            None => println!("No result"),
        }
        CmdResult {}
    }

    fn build_metrics(&self, labels: &Vec<String>, values: &Vec<f32>, ag: Option<(&str, f32)>) -> BTreeMap<String, f32> {
        let mut metrics: BTreeMap<String, f32> = BTreeMap::new();
        values.iter().enumerate().for_each(|(i, v)| {
            metrics.insert(labels[i].clone(), *v);
        });
        match ag {
            Some(a) => {
                metrics.insert(a.0.to_string(), a.1);
            },
            None => (),
        }
        metrics
    }
}
