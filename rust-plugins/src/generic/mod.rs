//! Core plugin logic: command definition, SNMP collection, metric evaluation, and status reporting.
//!
//! A [`Command`] is deserialized from JSON and describes what to collect via SNMP
//! and how to compute metrics from the collected values.  Calling [`Command::execute`]
//! performs the full pipeline and returns a [`CmdResult`] containing the Nagios-style
//! output string and the overall [`Status`].

extern crate regex;
extern crate serde;
extern crate serde_json;

pub mod error;

use self::error::Result;
use crate::compute::{Compute, Parser, ast::ExprResult, threshold::Threshold};
use crate::output::{Output, OutputFormatter};
use crate::snmp::{snmp_bulk_get, snmp_bulk_walk, snmp_bulk_walk_with_labels};
use log::{debug, trace};
use regex::Regex;
use serde::Deserialize;
use std::collections::HashMap;

use crate::snmp::SnmpResult;

/// A single metric data point, ready to be included in plugin output.
///
/// The `name` identifies the metric instance (e.g. `"0#memory_used"`).
/// `uom` is the unit of measurement string (e.g. `"B"`, `"%"`).
#[derive(Debug)]
pub struct Perfdata<'p> {
    pub name: String,
    pub value: f64,
    pub uom: &'p str,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub warning: Option<&'p str>,
    pub critical: Option<&'p str>,
    pub status: Option<Status>,
}

/// Nagios-compatible plugin exit status.
///
/// The numeric values match the Nagios/Centreon convention:
/// `0 = OK`, `1 = WARNING`, `2 = CRITICAL`, `3 = UNKNOWN`.
#[derive(Debug, Copy, Clone, PartialEq)]
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

    /// Returns `true` if `self` is at least as severe as `other`.
    ///
    /// Severity order: `Ok < Warning < Unknown < Critical`.
    pub fn is_worse_than(&self, other: Status) -> bool {
        let self_int = match self {
            Status::Ok => 0,
            Status::Warning => 1,
            Status::Critical => 3,
            Status::Unknown => 2,
        };
        let other_int = match other {
            Status::Ok => 0,
            Status::Warning => 1,
            Status::Critical => 3,
            Status::Unknown => 2,
        };
        self_int >= other_int
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

/// Type of SNMP query to perform for a given OID.
#[derive(Deserialize, Debug)]
enum QueryType {
    /// Retrieve a single leaf OID value (`GetBulkRequest` with one OID).
    Get,
    /// Walk a subtree using repeated `GetBulkRequest` calls.
    Walk,
}

/// Description of a single SNMP collection entry as read from the JSON config.
#[derive(Deserialize, Debug)]
pub struct Snmp {
    /// Logical name used to reference collected values in compute expressions.
    name: String,
    /// The OID to query (may start with a leading `.`).
    oid: String,
    query: QueryType,
    /// Optional label map used by [`snmp_bulk_walk_with_labels`] to split
    /// a subtree walk into named sub-vectors.
    labels: Option<HashMap<String, String>>,
}

/// Groups all SNMP queries that must be executed before computing metrics.
#[derive(Deserialize, Debug)]
pub struct Collect {
    snmp: Vec<Snmp>,
}

/// Top-level plugin command deserialized from the JSON configuration file.
///
/// A `Command` ties together SNMP collection, metric computation, and output
/// formatting.  Use [`Command::execute`] to run the full pipeline.
#[derive(Deserialize, Debug)]
pub struct Command {
    collect: Collect,
    compute: Compute,
    #[serde(default = "default_output")]
    pub output: Output,
}

fn default_output() -> Output {
    Output::new()
}

/// Result of executing a [`Command`].
#[derive(Debug)]
pub struct CmdResult {
    /// Overall plugin status (worst status across all metrics).
    pub status: Status,
    /// Nagios-compatible output string ready to be printed to stdout.
    pub output: String,
}

fn compute_status(value: &f64, warn: &Option<String>, crit: &Option<String>) -> Result<Status> {
    if let Some(c) = crit {
        let crit = Threshold::parse(c)?;
        if crit.in_alert(*value) {
            return Ok(Status::Critical);
        }
    }
    if let Some(w) = warn {
        let warn = Threshold::parse(w)?;
        if warn.in_alert(*value) {
            return Ok(Status::Warning);
        }
    }
    Ok(Status::Ok)
}

impl Command {
    /// Sets the warning threshold for the metric identified by `name`
    /// (matched against `threshold_suffix` in the compute config).
    pub fn add_warning(&mut self, name: &str, value: String) {
        if let Some(metric) =
            self.compute
                .metrics
                .iter_mut()
                .find(|metric| match &metric.threshold_suffix {
                    Some(suffix) => suffix == name,
                    None => false,
                })
        {
            debug!("Adding warning to metric {}", metric.name);
            metric.warning = Some(value);
        } else if let Some(aggregations) = self.compute.aggregations.as_mut() {
            if let Some(metric) =
                aggregations
                    .iter_mut()
                    .find(|metric| match &metric.threshold_suffix {
                        Some(suffix) => suffix == name,
                        None => false,
                    })
            {
                debug!("Adding warning to aggregation metric {}", metric.name);
                metric.warning = Some(value);
            }
        }
    }

    /// Sets the critical threshold for the metric identified by `name`
    /// (matched against `threshold_suffix` in the compute config).
    pub fn add_critical(&mut self, name: &str, value: String) {
        if let Some(metric) =
            self.compute
                .metrics
                .iter_mut()
                .find(|metric| match &metric.threshold_suffix {
                    Some(suffix) => suffix == name,
                    None => false,
                })
        {
            metric.critical = Some(value);
            debug!("Adding critical to metric {}", metric.name);
        } else if let Some(aggregations) = self.compute.aggregations.as_mut() {
            if let Some(metric) =
                aggregations
                    .iter_mut()
                    .find(|metric| match &metric.threshold_suffix {
                        Some(suffix) => suffix == name,
                        None => false,
                    })
            {
                debug!("Adding critical to aggregation metric {}", metric.name);
                metric.critical = Some(value);
            }
        }
    }

    /// Executes all configured SNMP queries (Get and Walk operations) and returns the results.
    fn execute_snmp_collect(
        &self,
        target: &str,
        version: &str,
        community: &str,
    ) -> Vec<SnmpResult> {
        let mut collect: Vec<SnmpResult> = Vec::new();
        let mut to_get = Vec::new();
        let mut get_name = Vec::new();
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
        collect
    }

    /// Executes the complete plugin pipeline: SNMP collection, metric computation, filtering, and output formatting.
    ///
    /// # Arguments
    /// * `target` - The target address in "host:port" format
    /// * `version` - SNMP version string (e.g., "2c")
    /// * `community` - SNMP community string
    /// * `filter_in` - Regex patterns; metrics matching any pattern are kept (empty = keep all)
    /// * `filter_out` - Regex patterns; metrics matching any pattern are excluded
    ///
    /// # Returns
    /// A [`CmdResult`] containing the overall [`Status`] and Nagios-compatible output string.
    pub fn execute(
        &self,
        target: &str,
        version: &str,
        community: &str,
        filter_in: &Vec<String>,
        filter_out: &Vec<String>,
    ) -> Result<CmdResult> {
        let mut collect = self.execute_snmp_collect(target, version, community);

        let mut idx: u32 = 0;
        let mut metrics = vec![];
        let mut my_res = SnmpResult::new(HashMap::new());
        let mut status = Status::Ok;

        // Prepare filters
        let mut re_in: Vec<Regex> = Vec::new();
        for f in filter_in.iter() {
            let re = Regex::new(f)?;
            re_in.push(re);
        }

        let mut re_out: Vec<Regex> = Vec::new();
        for f in filter_out.iter() {
            let re = Regex::new(f)?;
            re_out.push(re);
        }

        for metric in self.compute.metrics.iter() {
            let value = &metric.value;
            let parser = Parser::new(&collect);
            let value = parser.eval(value).unwrap();
            let min = if let Some(min_expr) = metric.min_expr.as_ref() {
                parser.eval(&min_expr).unwrap()
            } else if let Some(min_value) = metric.min {
                ExprResult::Number(min_value)
            } else {
                ExprResult::Empty
            };
            let max = if let Some(max_expr) = metric.max_expr.as_ref() {
                parser.eval(&max_expr).unwrap()
            } else if let Some(max_value) = metric.max {
                ExprResult::Number(max_value)
            } else {
                ExprResult::Empty
            };

            let compute_threshold = |idx: usize, expr: &ExprResult| match &expr {
                ExprResult::Number(value) => Some(*value),
                ExprResult::Vector(v) => Some(v[idx]),
                _ => None,
            };
            match &value {
                ExprResult::Vector(v) => {
                    let prefix_str = match &metric.prefix {
                        Some(prefix) => parser.eval_str(prefix).unwrap(),
                        None => ExprResult::Empty,
                    };
                    for (i, item) in v.iter().enumerate() {
                        let name = match &prefix_str {
                            ExprResult::StrVector(v) => {
                                format!("{:?}#{}", v[i], metric.name)
                            }
                            ExprResult::Empty => {
                                let res = format!("{}#{}", idx, metric.name);
                                idx += 1;
                                res
                            }
                            _ => {
                                panic!("A label must be a string");
                            }
                        };
                        if !re_in.is_empty() {
                            if !re_in.iter().any(|re| re.is_match(&name)) {
                                continue;
                            }
                        }
                        if !re_out.is_empty() {
                            if re_out.iter().any(|re| re.is_match(&name)) {
                                continue;
                            }
                        }
                        let current_status =
                            compute_status(item, &metric.warning, &metric.critical)?;
                        status = worst(status, current_status);
                        let w = match metric.warning {
                            Some(ref w) => Some(w.as_str()),
                            None => None,
                        };
                        let c = match metric.critical {
                            Some(ref c) => Some(c.as_str()),
                            None => None,
                        };
                        let m = Perfdata {
                            name,
                            value: *item,
                            uom: &metric.uom,
                            min: compute_threshold(i, &min),
                            max: compute_threshold(i, &max),
                            warning: w,
                            critical: c,
                            status: Some(current_status),
                        };
                        trace!("New metric '{}' with value {:?}", m.name, m.value);
                        metrics.push(m);
                    }
                }
                ExprResult::Number(s) => {
                    let name = match &metric.prefix {
                        Some(prefix) => {
                            format!("{:?}#{}", prefix, metric.name)
                        }
                        None => {
                            let res = format!("{}#{}", idx, metric.name);
                            idx += 1;
                            res
                        }
                    };
                    if !re_in.is_empty() {
                        // If one filter is matched, we keep the metric
                        if !re_in.iter().any(|re| re.is_match(&name)) {
                            continue;
                        }
                    }
                    if !re_out.is_empty() {
                        if re_out.iter().any(|re| re.is_match(&name)) {
                            continue;
                        }
                    }
                    let current_status = compute_status(s, &metric.warning, &metric.critical)?;
                    status = worst(status, current_status);
                    let w = match metric.warning {
                        Some(ref w) => Some(w.as_str()),
                        None => None,
                    };
                    let c = match metric.critical {
                        Some(ref c) => Some(c.as_str()),
                        None => None,
                    };
                    let m = Perfdata {
                        name,
                        value: *s,
                        uom: &metric.uom,
                        min: compute_threshold(0, &min),
                        max: compute_threshold(0, &max),
                        warning: w,
                        critical: c,
                        status: Some(current_status),
                    };
                    trace!("New metric '{}' with value {:?}", m.name, m.value);
                    metrics.push(m);
                }
                _ => panic!("Aggregation must be applied to a vector"),
            }
            let key = format!("metrics.{}", metric.name);
            debug!("New ID '{}' with content: {:?}", key, value);
            my_res.items.insert(key, value);
        }
        collect.push(my_res);
        if let Some(aggregations) = self.compute.aggregations.as_ref() {
            let mut my_res = SnmpResult::new(HashMap::new());
            for metric in aggregations {
                let value = &metric.value;
                let parser = Parser::new(&collect);
                let max = if let Some(max_expr) = metric.max_expr.as_ref() {
                    let res = parser.eval(&max_expr).unwrap();
                    Some(match res {
                        ExprResult::Number(v) => v,
                        ExprResult::Vector(v) => {
                            assert!(v.len() == 1);
                            v[0]
                        }
                        _ => panic!("Aggregation must be applied to a vector"),
                    })
                } else if let Some(max_value) = metric.max {
                    Some(max_value)
                } else {
                    None
                };
                let min = if let Some(min_expr) = metric.min_expr.as_ref() {
                    let res = parser.eval(&min_expr).unwrap();
                    Some(match res {
                        ExprResult::Number(v) => v,
                        ExprResult::Vector(v) => {
                            assert!(v.len() == 1);
                            v[0]
                        }
                        _ => panic!("Aggregation must be applied to a vector"),
                    })
                } else if let Some(min_value) = metric.min {
                    Some(min_value)
                } else {
                    None
                };
                let value = parser.eval(value).unwrap();
                match &value {
                    ExprResult::Vector(v) => {
                        for item in v {
                            let name = match &metric.prefix {
                                Some(prefix) => {
                                    format!("{:?}#{}", prefix, metric.name)
                                }
                                None => {
                                    let res = format!("{}#{}", idx, metric.name);
                                    idx += 1;
                                    res
                                }
                            };
                            let current_status =
                                compute_status(item, &metric.warning, &metric.critical)?;
                            status = worst(status, current_status);
                            let w = match metric.warning {
                                Some(ref w) => Some(w.as_str()),
                                None => None,
                            };
                            let c = match metric.critical {
                                Some(ref c) => Some(c.as_str()),
                                None => None,
                            };
                            let m = Perfdata {
                                name,
                                value: *item,
                                uom: &metric.uom,
                                min,
                                max,
                                warning: w,
                                critical: c,
                                status: Some(current_status),
                            };
                            trace!("New metric '{}' with value {:?}", m.name, m.value);
                            metrics.push(m);
                        }
                    }
                    ExprResult::Number(s) => {
                        let name = &metric.name;
                        let current_status = compute_status(s, &metric.warning, &metric.critical)?;
                        status = worst(status, current_status);
                        let w = match metric.warning {
                            Some(ref w) => Some(w.as_str()),
                            None => None,
                        };
                        let c = match metric.critical {
                            Some(ref c) => Some(c.as_str()),
                            None => None,
                        };
                        let m = Perfdata {
                            name: name.to_string(),
                            value: *s,
                            uom: &metric.uom,
                            min,
                            max,
                            warning: w,
                            critical: c,
                            status: Some(current_status),
                        };
                        trace!("New metric '{}' with value {:?}", m.name, m.value);
                        metrics.push(m);
                    }
                    _ => panic!("Aggregation must be applied to a vector"),
                }
                let key = format!("aggregations.{}", metric.name);
                debug!("New ID '{}' with content: {:?}", key, value);
                my_res.items.insert(key, value);
            }
            collect.push(my_res);
        }

        debug!("collect: {:#?}", collect);
        trace!("metrics: {:#?}", metrics);
        let output_formatter = OutputFormatter::new(status, &collect, &metrics, &self.output);
        let output = output_formatter.to_string();
        Ok(CmdResult { status, output })
    }
}
