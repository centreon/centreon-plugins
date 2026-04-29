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
    /// String used to separate metric instances in the detail message.
    #[serde(default = "default_instance_separator")]
    instance_separator: String,
    /// String used to separate individual metrics in perfdata.
    #[serde(default = "default_metric_separator")]
    metric_separator: String,
}

fn default_ok() -> String {
    "Everything is OK".to_string()
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
            instance_separator: default_instance_separator(),
            metric_separator: default_metric_separator(),
        }
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
                    return format!("{} | {}", detail, metrics);
                } else {
                    let parser = Parser::new(&self.collect);
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
                    return format!("{} | {}", output, metrics);
                }
            }
            Status::Warning => {
                if self.output_formatter.detail_warning {
                    let detail = self.build_detail(&self.output_formatter.warning);
                    return format!("{} | {}", detail, metrics);
                } else {
                    return format!("{} | {}", self.output_formatter.warning, metrics);
                }
            }
            Status::Critical => {
                if self.output_formatter.detail_critical {
                    let detail = self.build_detail(&self.output_formatter.critical);
                    return format!("{} | {}", detail, metrics);
                } else {
                    return format!("{} | {}", self.output_formatter.critical, metrics);
                }
            }
            Status::Unknown => {
                if self.output_formatter.detail_unknown {
                    let detail = self.build_detail(&self.output_formatter.unknown);
                    return format!("{} | {}", detail, metrics);
                } else {
                    return format!("{} | {}", self.output_formatter.unknown, metrics);
                }
            }
        }
    }

    /// Builds a detailed message string including the prefix and metrics that
    /// triggered the current status.
    fn build_detail(&self, prefix: &str) -> String {
        let mut v = Vec::new();
        for m in self.metrics.iter() {
            if let Some(status) = m.status {
                if status.is_worse_than(self.status) {
                    v.push(std::format!("{} is {}{}", m.name, float_string(&m.value), m.uom));
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
