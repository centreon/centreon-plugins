//! Formatting plugin output in Nagios/Centreon-compatible format.
//!
//! Produces output like: `STATUS message | metric1=value1;warn;crit;min;max metric2=...`

use crate::compute::Parser;
use crate::compute::ast::ExprResult;
use crate::generic::{Perfdata, Status};
use crate::snmp::SnmpResult;
use log::error;
use serde::Deserialize;

/// Configurable status messages and separators for plugin output.
#[derive(Deserialize, Debug)]
pub struct Output {
    /// Message template for OK status.
    #[serde(default = "default_ok")]
    pub ok: String,
    /// If true, include affected metrics in the OK message.
    #[serde(default = "default_bool_false")]
    detail_ok: bool,
    /// Message prefix for WARNING status.
    #[serde(default = "default_warning")]
    pub warning: String,
    /// If true, include affected metrics in the WARNING message.
    #[serde(default = "default_bool_true")]
    detail_warning: bool,
    /// Message prefix for CRITICAL status.
    #[serde(default = "default_critical")]
    pub critical: String,
    /// If true, include affected metrics in the CRITICAL message.
    #[serde(default = "default_bool_true")]
    detail_critical: bool,
    /// Message prefix for UNKNOWN status.
    #[serde(default = "default_unknown")]
    pub unknown: String,
    /// If true, include affected metrics in the UNKNOWN message.
    #[serde(default = "default_bool_true")]
    detail_unknown: bool,
    /// Message used when no metric is left once the filters are applied.
    /// The status name given by `--no-data-status` is prepended to it.
    #[serde(default = "default_no_data")]
    pub no_data: String,
    /// String used to separate metric instances in the detail message.
    #[serde(default = "default_instance_separator")]
    instance_separator: String,
    /// String used to separate individual metrics in perfdata.
    #[serde(default = "default_metric_separator")]
    metric_separator: String,
}

fn default_ok() -> String {
    "OK: Everything is ok ".to_string()
}
fn default_warning() -> String {
    "WARNING: ".to_string()
}
fn default_critical() -> String {
    "CRITICAL: ".to_string()
}
fn default_unknown() -> String {
    "UNKNOWN: ".to_string()
}
fn default_no_data() -> String {
    "No data matching the filters".to_string()
}
fn default_instance_separator() -> String {
    " - ".to_string()
}
fn default_metric_separator() -> String {
    ", ".to_string()
}
fn default_bool_false() -> bool {
    false
}
fn default_bool_true() -> bool {
    true
}

impl Output {
    /// Creates an `Output` with default Nagios-compatible messages and separators.
    pub fn new() -> Output {
        Output {
            ok: default_ok(),
            detail_ok: false,
            warning: default_warning(),
            detail_warning: true,
            critical: default_critical(),
            detail_critical: true,
            unknown: default_unknown(),
            detail_unknown: true,
            no_data: default_no_data(),
            instance_separator: default_instance_separator(),
            metric_separator: default_metric_separator(),
        }
    }
}

/// Joins the human-readable output text with the perfdata section.
///
/// The ` | ` separator is only emitted when there is perfdata to show —
/// a status-only plugin (all metrics flagged `perfdata: false`) must not
/// end with a dangling pipe.
fn join_output(text: &str, metrics: &str) -> String {
    if metrics.is_empty() {
        text.trim_end().to_string()
    } else {
        format!("{} | {}", text, metrics)
    }
}

/// Formats plugin results into Nagios-compatible output string.
pub struct OutputFormatter<'a> {
    status: Status,
    collect: &'a Vec<SnmpResult>,
    metrics: &'a Vec<Perfdata<'a>>,
    output_formatter: &'a Output,
}

impl<'a> OutputFormatter<'a> {
    /// Creates a new formatter with the given status, metrics, and output configuration.
    pub fn new(
        status: Status,
        collect: &'a Vec<SnmpResult>,
        metrics: &'a Vec<Perfdata>,
        formatter: &'a Output,
    ) -> OutputFormatter<'a> {
        OutputFormatter {
            status,
            collect,
            metrics,
            output_formatter: formatter,
        }
    }

    /// Generates the complete Nagios-compatible output string.
    pub fn to_string(&self) -> String {
        let metrics = self
            .metrics
            .iter()
            // Metrics flagged `perfdata: false` (e.g. mapped status metrics)
            // are excluded from perfdata but still drive detail messages.
            .filter(|m| m.perfdata)
            .map(|m| {
                format!(
                    "{}={}{};{};{};{};{}",
                    m.name,
                    float_string(&m.value),
                    m.uom,
                    m.warning.unwrap_or(""),
                    m.critical.unwrap_or(""),
                    match m.min {
                        Some(min) => float_string(&min),
                        None => "".to_string(),
                    },
                    match m.max {
                        Some(max) => float_string(&max),
                        None => "".to_string(),
                    }
                )
            })
            .collect::<Vec<String>>()
            .join(" ");
        match self.status {
            Status::Ok => {
                if self.output_formatter.detail_ok {
                    let detail = self.build_detail(&self.output_formatter.ok);
                    return join_output(&detail, &metrics);
                } else {
                    let parser = Parser::new(&self.collect, false);
                    let res = parser.eval_str(&self.output_formatter.ok);
                    let output = match res {
                        Ok(output) => match output {
                            ExprResult::Str(output) => output,
                            ExprResult::Number(_) => {
                                error!(
                                    "Output expression evaluated to a number, expected a string"
                                );
                                return "".to_string();
                            }
                            ExprResult::StrVector(v) => {
                                if v.len() == 1 {
                                    let output = v[0].clone();
                                    output
                                } else {
                                    error!(
                                        "Output expression evaluated to a vector with more than one element, expected a single string"
                                    );
                                    return "".to_string();
                                }
                            }
                            _ => "".to_string(),
                        },
                        Err(err) => {
                            error!("Error evaluating output expression: {:?}", err);
                            self.output_formatter.ok.clone()
                        }
                    };
                    return join_output(&output, &metrics);
                }
            }
            Status::Warning => {
                if self.output_formatter.detail_warning {
                    let detail = self.build_detail(&self.output_formatter.warning);
                    return join_output(&detail, &metrics);
                } else {
                    return join_output(&self.output_formatter.warning, &metrics);
                }
            }
            Status::Critical => {
                if self.output_formatter.detail_critical {
                    let detail = self.build_detail(&self.output_formatter.critical);
                    return join_output(&detail, &metrics);
                } else {
                    return join_output(&self.output_formatter.critical, &metrics);
                }
            }
            Status::Unknown => {
                if self.output_formatter.detail_unknown {
                    let detail = self.build_detail(&self.output_formatter.unknown);
                    return join_output(&detail, &metrics);
                } else {
                    return join_output(&self.output_formatter.unknown, &metrics);
                }
            }
        }
    }

    /// Builds a detailed message string including the prefix and metrics that
    /// triggered the current status.
    ///
    /// When a metric carries a mapped label (`value-map`), the label is shown
    /// instead of the raw number (e.g. `status is down`, not `status is 2`).
    fn build_detail(&self, prefix: &str) -> String {
        let mut v = Vec::new();
        for m in self.metrics.iter() {
            if let Some(status) = m.status {
                if status.is_worse_than(self.status) {
                    let displayed = match &m.label {
                        Some(label) => label.clone(),
                        None => format!("{}{}", float_string(&m.value), m.uom),
                    };
                    v.push(std::format!("{} is {}", m.name, displayed));
                }
            }
        }
        std::format!(
            "{}{}",
            prefix,
            v.join::<&str>(&self.output_formatter.metric_separator)
        )
    }
}

/// Converts a floating point number to a string with two decimal places,
/// removing trailing zeros and the decimal point if necessary.
/// This is useful for formatting metrics in a more human-readable way.
///
/// For example:
/// ```
/// let val = 40.009;
/// let formatted = float_string(&val);
/// // assert_eq!(formatted, "40.01");
/// let val = 40.0;
/// let formatted = float_string(&val);
/// // assert_eq!(formatted, "40");
/// ```
pub fn float_string(val: &f64) -> String {
    let mut s = format!("{:.2}", val);
    while s.ends_with('0') {
        s.pop();
    }
    if s.ends_with('.') {
        s.pop();
    }
    s
}

mod test {

    #[test]
    fn test_float_string() {
        use super::float_string;

        let f = f64::default();
        assert_eq!(float_string(&40.0), "40");
        assert_eq!(float_string(&40.00), "40");
        assert_eq!(float_string(&40.001), "40");
        assert_eq!(float_string(&40.009), "40.01");

        assert_eq!(float_string(&40.01), "40.01");
        assert_eq!(float_string(&40.104), "40.1");

        assert_eq!(float_string(&f), "0");
        assert_eq!(float_string(&9999999.999), "10000000");
    }
}

#[cfg(test)]
mod value_map_tests {
    use super::*;

    fn perfdata<'p>(
        name: &str,
        value: f64,
        status: Status,
        label: Option<String>,
        perfdata: bool,
    ) -> Perfdata<'p> {
        Perfdata {
            name: name.to_string(),
            value,
            uom: "",
            min: None,
            max: None,
            warning: None,
            critical: None,
            status: Some(status),
            label,
            perfdata,
        }
    }

    #[test]
    fn detail_shows_mapped_label_and_perfdata_flag_hides_metric() {
        let collect: Vec<SnmpResult> = vec![];
        let output = Output::new();
        let metrics = vec![
            perfdata(
                "'eth0#interface.status'",
                2.0,
                Status::Critical,
                Some("down".to_string()),
                false,
            ),
            perfdata("cpu", 42.0, Status::Ok, None, true),
        ];
        let formatter = OutputFormatter::new(Status::Critical, &collect, &metrics, &output);
        let s = formatter.to_string();
        // The label replaces the raw number in the detail message...
        assert!(s.contains("'eth0#interface.status' is down"), "got: {}", s);
        // ...and the status metric is excluded from the perfdata section,
        // while the regular metric remains.
        assert!(!s.contains("interface.status'=2"), "got: {}", s);
        assert!(s.contains("cpu=42"), "got: {}", s);
    }

    #[test]
    fn empty_perfdata_omits_the_pipe_separator() {
        let collect: Vec<SnmpResult> = vec![];
        let output = Output::new();
        let metrics = vec![perfdata(
            "'eth0#interface.status'",
            1.0,
            Status::Ok,
            Some("up".to_string()),
            false,
        )];
        let formatter = OutputFormatter::new(Status::Ok, &collect, &metrics, &output);
        let s = formatter.to_string();
        assert!(!s.contains('|'), "no dangling pipe expected, got: {}", s);
    }
}
