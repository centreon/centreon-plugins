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
use crate::snmp::SnmpResult;
use crate::snmp::{snmp_bulk_get, snmp_bulk_walk, snmp_bulk_walk_with_labels, SnmpConfig};
use log::{debug, trace};
use regex::Regex;
use serde::Deserialize;
use std::collections::HashMap;
use std::convert::Into;

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
impl Into<i32> for Status {
    fn into(self) -> i32 {
        match self {
            Status::Ok => 0,
            Status::Warning => 1,
            Status::Critical => 2,
            Status::Unknown => 3,
        }
    }
}
impl Into<String> for Status {
    fn into(self) -> String {
        match self {
            Status::Ok => "OK".to_string(),
            Status::Warning => "WARNING".to_string(),
            Status::Critical => "CRITICAL".to_string(),
            Status::Unknown => "UNKNOWN".to_string(),
        }
    }
}
impl std::str::FromStr for Status {
    type Err = error::Error;

    /// Parses a status from its textual form, case-insensitively
    /// (e.g. `"critical"`, `"CRITICAL"`).
    fn from_str(s: &str) -> Result<Self> {
        match s.trim().to_lowercase().as_str() {
            "ok" => Ok(Status::Ok),
            "warning" => Ok(Status::Warning),
            "critical" => Ok(Status::Critical),
            "unknown" => Ok(Status::Unknown),
            _ => Err(error::Error::InvalidStatus {
                value: s.to_string(),
            }),
        }
    }
}
impl Status {
    /// Returns the severity rank of the status, used to compare statuses.
    ///
    /// Severity order: `Ok < Warning < Unknown < Critical`.  It differs from the
    /// exit code (see [`Into<i32>`]), where `Critical` is 2 and `Unknown` is 3.
    fn severity(&self) -> u8 {
        match self {
            Status::Ok => 0,
            Status::Warning => 1,
            Status::Unknown => 2,
            Status::Critical => 3,
        }
    }

    /// Returns `true` if `self` is at least as severe as `other`.
    ///
    /// Severity order: `Ok < Warning < Unknown < Critical`.
    pub fn is_worse_than(&self, other: Status) -> bool {
        self.severity() >= other.severity()
    }
}

fn worst(a: Status, b: Status) -> Status {
    if a.severity() > b.severity() { a } else { b }
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
    /// Optional per-query override of the GetBulk `max-repetitions`
    /// (defaults to the global value, see the `--maxrepetitions` CLI option).
    #[serde(rename = "max-repetitions")]
    max_repetitions: Option<u32>,
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

/// Parses a Nagios threshold specification once, with an error message that
/// names the metric and the field. Called once per metric — never per value:
/// re-parsing the same string for every element of a 10 000-interface table
/// would be pure waste.
fn parse_threshold(
    spec: &Option<String>,
    metric_name: &str,
    field: &str,
) -> Result<Option<Threshold>> {
    spec.as_deref()
        .map(Threshold::parse)
        .transpose()
        .map_err(|e| error::Error::InvalidJSON {
            message: format!("Metric \"{}\", field \"{}\": {}", metric_name, field, e),
        })
}

/// Evaluates a value against pre-parsed warning/critical thresholds.
fn compute_status(value: f64, warn: Option<&Threshold>, crit: Option<&Threshold>) -> Status {
    if let Some(crit) = crit {
        if crit.in_alert(value) {
            return Status::Critical;
        }
    }
    if let Some(warn) = warn {
        if warn.in_alert(value) {
            return Status::Warning;
        }
    }
    Status::Ok
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

    /// Formats raw SNMP response for simple display
    fn format_raw_response(&self, collect: &Vec<SnmpResult>) -> Result<CmdResult> {
        let mut lines = Vec::new();

        for result in collect.iter() {
            for (name, expr_result) in &result.items {
                for val in expr_result.values() {
                    lines.push(format!("{}: {}", name, val));
                }
            }
        }

        let output = if lines.len() <= 1 {
            format!(
                "OK: {}",
                lines.first().unwrap_or(&"No response".to_string())
            )
        } else {
            format!("OK: Response received\n{}", lines.join("\n"))
        };

        Ok(CmdResult {
            status: Status::Ok,
            output,
        })
    }

    /// Executes all configured SNMP queries (Get and Walk operations) and returns the results.
    fn execute_snmp_collect(
        &self,
        config: &SnmpConfig,
        check_format: bool,
    ) -> Result<Vec<SnmpResult>> {
        let mut collect: Vec<SnmpResult> = Vec::new();
        // Single deadline for ALL queries of this collection: the global
        // time budget covers the sum of the walks and gets, not each one.
        let deadline = config.deadline();

        if check_format {
            // In check-format mode, don't make SNMP requests and initialize with dummy values.
            // Get queries return a single value; Walk queries return multiple values.
            for s in self.collect.snmp.iter() {
                let mut items = HashMap::new();
                let dummy = match s.query {
                    QueryType::Get => ExprResult::Vector(vec![0.0]),
                    QueryType::Walk => ExprResult::Vector(vec![0.0, 0.0]),
                };
                items.insert(s.name.clone(), dummy);
                if let Some(lab) = &s.labels {
                    for label_val in lab.values() {
                        let key = format!("{}.{}", s.name, label_val);
                        items.insert(key, ExprResult::Vector(vec![0.0, 0.0]));
                    }
                }
                collect.push(SnmpResult::new(items));
            }
            return Ok(collect);
        }
        let mut to_get = Vec::new();
        let mut get_name = Vec::new();
        for s in self.collect.snmp.iter() {
            match s.query {
                QueryType::Walk => {
                    let max_repetitions = s.max_repetitions.unwrap_or(config.max_repetitions);
                    if let Some(lab) = &s.labels {
                        let r = snmp_bulk_walk_with_labels(
                            config,
                            deadline,
                            &s.oid,
                            &s.name,
                            lab,
                            max_repetitions,
                        )?;
                        if !r.items.is_empty() {
                            collect.push(r);
                        }
                    } else {
                        let r =
                            snmp_bulk_walk(config, deadline, &s.oid, &s.name, max_repetitions)?;
                        if !r.items.is_empty() {
                            collect.push(r);
                        }
                    }
                }
                QueryType::Get => {
                    to_get.push(s.oid.as_str());
                    get_name.push(s.name.as_str());
                }
            }
        }

        if !to_get.is_empty() {
            let r = snmp_bulk_get(config, deadline, 1, 1, &to_get, &get_name);
            collect.push(r?);
        }
        if collect.is_empty() {
            return Err(error::Error::EmptyResponse {});
        }
        Ok(collect)
    }

    /// Executes the complete plugin pipeline: SNMP collection, metric computation, filtering, and output formatting.
    ///
    /// # Arguments
    /// * `config` - SNMP connection parameters (target, community, timeouts, retries)
    /// * `filter_in` - Regex patterns; metrics matching any pattern are kept (empty = keep all)
    /// * `filter_out` - Regex patterns; metrics matching any pattern are excluded
    /// * `check_format` - Dry-run mode ( validate macros )
    /// * `check_response` - Display raw SNMP response without metrics computation
    /// * `no_data_status` - Status to report when no metric is left once the filters are applied
    ///
    /// # Returns
    /// A [`CmdResult`] containing the overall [`Status`] and Nagios-compatible output string.
    pub fn execute(
        &self,
        config: &SnmpConfig,
        filter_in: &Vec<String>,
        filter_out: &Vec<String>,
        check_format: bool,
        check_response: bool,
        no_data_status: Status,
    ) -> Result<CmdResult> {
        let mut collect = self.execute_snmp_collect(config, check_format)?;

        if check_response {
            return self.format_raw_response(&collect);
        }

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
            let parser = Parser::new(&collect, check_format);
            let value = parser.eval(value).map_err(|e| error::Error::InvalidJSON {
                message: format!("Metric \"{}\", field \"value\": {}", metric.name, e),
            })?;
            let min = if let Some(min_expr) = metric.min_expr.as_ref() {
                parser
                    .eval(&min_expr)
                    .map_err(|e| error::Error::InvalidJSON {
                        message: format!("Metric \"{}\", field \"min_expr\": {}", metric.name, e),
                    })?
            } else if let Some(min_value) = metric.min {
                ExprResult::Number(min_value)
            } else {
                ExprResult::Empty
            };
            let max = if let Some(max_expr) = metric.max_expr.as_ref() {
                parser
                    .eval(&max_expr)
                    .map_err(|e| error::Error::InvalidJSON {
                        message: format!("Metric \"{}\", field \"max_expr\": {}", metric.name, e),
                    })?
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
            // Thresholds are parsed once per metric, then evaluated per value.
            let warn_threshold = parse_threshold(&metric.warning, &metric.name, "warning")?;
            let crit_threshold = parse_threshold(&metric.critical, &metric.name, "critical")?;
            match &value {
                ExprResult::Vector(v) => {
                    let prefix_str = match &metric.prefix {
                        Some(prefix) => {
                            parser
                                .eval_str(prefix)
                                .map_err(|e| error::Error::InvalidJSON {
                                    message: format!(
                                        "Metric \"{}\", field \"prefix\": {}",
                                        metric.name, e
                                    ),
                                })?
                        }
                        None => ExprResult::Empty,
                    };
                    for (i, item) in v.iter().enumerate() {
                        // first, compose the instance name
                        let instance_name = match &prefix_str {
                            ExprResult::StrVector(v) => v[i].to_string(),
                            ExprResult::Str(s) => s.to_string(),
                            ExprResult::Empty => {
                                let res = idx.to_string();
                                idx += 1;
                                res
                            }
                            _ => {
                                panic!("A label must be a string");
                            }
                        };
                        // then apply filters exclusion and inclusion filters
                        if !re_out.is_empty() && re_out.iter().any(|re| re.is_match(&instance_name))
                        {
                            continue;
                        }
                        if (!re_in.is_empty()
                            && !re_in.iter().any(|re| re.is_match(&instance_name)))
                        {
                            continue;
                        }
                        // and now concatenate to form the full perfdata
                        let name = format!("'{}#{}'", instance_name, metric.name);
                        let current_status =
                            compute_status(*item, warn_threshold.as_ref(), crit_threshold.as_ref());
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
                            format!("{}#{}", prefix, metric.name)
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
                    let current_status =
                        compute_status(*s, warn_threshold.as_ref(), crit_threshold.as_ref());
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

        // Nothing left to report: every instance has been discarded by the filters
        // (or none was collected at all). Aggregations are skipped on purpose, as they
        // would be computed on values that have just been filtered out.
        if !self.compute.metrics.is_empty() && metrics.is_empty() {
            debug!(
                "No metric left, reporting the no-data status {:?}",
                no_data_status
            );
            let status_str: String = no_data_status.into();
            return Ok(CmdResult {
                status: no_data_status,
                output: format!("{}: {}", status_str, self.output.no_data),
            });
        }

        collect.push(my_res);
        if let Some(aggregations) = self.compute.aggregations.as_ref() {
            let mut my_res = SnmpResult::new(HashMap::new());
            for metric in aggregations {
                let value = &metric.value;
                let parser = Parser::new(&collect, check_format);
                let max = if let Some(max_expr) = metric.max_expr.as_ref() {
                    let res = parser
                        .eval(&max_expr)
                        .map_err(|e| error::Error::InvalidJSON {
                            message: format!(
                                "Aggregation \"{}\", field \"max_expr\": {}",
                                metric.name, e
                            ),
                        })?;
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
                    let res = parser
                        .eval(&min_expr)
                        .map_err(|e| error::Error::InvalidJSON {
                            message: format!(
                                "Aggregation \"{}\", field \"min_expr\": {}",
                                metric.name, e
                            ),
                        })?;
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
                // Thresholds are parsed once per aggregation, then evaluated per value.
                let warn_threshold = parse_threshold(&metric.warning, &metric.name, "warning")?;
                let crit_threshold = parse_threshold(&metric.critical, &metric.name, "critical")?;
                let value = parser.eval(value).map_err(|e| error::Error::InvalidJSON {
                    message: format!("Aggregation \"{}\", field \"value\": {}", metric.name, e),
                })?;
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
                            let current_status = compute_status(
                                *item,
                                warn_threshold.as_ref(),
                                crit_threshold.as_ref(),
                            );
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
                        let current_status =
                            compute_status(*s, warn_threshold.as_ref(), crit_threshold.as_ref());
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

    /// Lists all available metrics
    pub fn list_counters(&self) {
        println!("Available metrics:");

        if !self.compute.metrics.is_empty() {
            for metric in &self.compute.metrics {
                let suffix = metric.threshold_suffix.as_deref().unwrap_or("(no suffix)");
                println!(
                    "  {} (--warning-{}, --critical-{})",
                    metric.name, suffix, suffix
                );
            }
        }

        if let Some(aggregations) = self.compute.aggregations.as_ref() {
            if !aggregations.is_empty() {
                println!("Aggregations:");
                for metric in aggregations {
                    let suffix = metric.threshold_suffix.as_deref().unwrap_or("(no suffix)");
                    println!(
                        "  {} (--warning-{}, --critical-{})",
                        metric.name, suffix, suffix
                    );
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn status_exit_codes_follow_the_monitoring_plugins_guidelines() {
        let codes: Vec<i32> = vec![
            Status::Ok.into(),
            Status::Warning.into(),
            Status::Critical.into(),
            Status::Unknown.into(),
        ];
        assert_eq!(codes, vec![0, 1, 2, 3]);
    }

    #[test]
    fn worst_ranks_critical_above_unknown() {
        assert_eq!(worst(Status::Ok, Status::Warning), Status::Warning);
        assert_eq!(worst(Status::Warning, Status::Unknown), Status::Unknown);
        assert_eq!(worst(Status::Unknown, Status::Critical), Status::Critical);
        assert_eq!(worst(Status::Critical, Status::Unknown), Status::Critical);
    }

    #[test]
    fn status_is_parsed_from_its_textual_form_whatever_the_case() {
        assert_eq!("ok".parse::<Status>().unwrap(), Status::Ok);
        assert_eq!("Warning".parse::<Status>().unwrap(), Status::Warning);
        assert_eq!("CRITICAL".parse::<Status>().unwrap(), Status::Critical);
        assert_eq!(" unknown ".parse::<Status>().unwrap(), Status::Unknown);
    }

    #[test]
    fn parsing_an_unsupported_status_returns_an_error() {
        let err = "pending".parse::<Status>().unwrap_err();
        assert!(matches!(
            err,
            error::Error::InvalidStatus { ref value } if value == "pending"
        ));
    }
}
