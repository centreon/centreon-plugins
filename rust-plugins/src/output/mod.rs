//! Formatting plugin output in Nagios/Centreon-compatible format.
//!
//! Produces output like: `STATUS message | metric1=value1;warn;crit;min;max metric2=...`

use crate::compute::Parser;
use crate::compute::ast::ExprResult;
use crate::generic::{Perfdata, Status};
use crate::snmp::SnmpResult;
use serde::Deserialize;
use tracing::error;

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
    /// Per-instance template appended to the OK message (non-`detail_ok`
    /// path only), e.g. `"CPU '{metrics.cpu.instance}' usage : {metrics.cpu:.2f} %"`.
    /// Absent: nothing is appended.
    instance: Option<String>,
    /// How `instance` is rendered when it evaluates to more than one
    /// value: joined into a single string with `instance_separator`.
    /// Currently the only supported mode; kept as a named, deserialized
    /// field so a config can state its intent and future modes can be
    /// added without a breaking JSON schema change.
    #[serde(default = "default_instance_display")]
    instance_display: String,
}

fn default_instance_display() -> String {
    "single".to_string()
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
            instance: None,
            instance_display: default_instance_display(),
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
                // Names are single-quoted, matching Perl: kept out of the
                // logical name so filters/templates match on the bare name.
                format!(
                    "'{}'={}{};{};{};{};{}",
                    m.name,
                    format_value(&m.value, m.decimals),
                    m.uom,
                    m.warning.as_deref().unwrap_or(""),
                    m.critical.as_deref().unwrap_or(""),
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
                    let output = match self.instances_text() {
                        Some(instances) => format!(
                            "{}{}{}",
                            output, self.output_formatter.instance_separator, instances
                        ),
                        None => output,
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
            if let Some(status) = m.status
                && status.is_worse_than(self.status)
            {
                if let Some(template) = m.output {
                    v.push(self.render_template(template));
                    continue;
                }
                v.push(std::format!(
                    "{} is {}{}",
                    m.name,
                    format_value(&m.value, m.decimals),
                    m.uom
                ));
            }
        }
        std::format!(
            "{}{}",
            prefix,
            v.join::<&str>(&self.output_formatter.metric_separator)
        )
    }

    /// Evaluates an output template against the collected results.
    fn eval_template(&self, template: &'a str) -> Result<ExprResult, String> {
        let parser = Parser::new(self.collect, false);
        parser.eval_str(template)
    }

    /// Evaluates an output template (a metric's `output` field) into a
    /// single detail-message string.
    ///
    /// A vector result (the template references a per-instance macro, e.g.
    /// `{metrics.cpu.instance}`) is flattened by joining its elements with
    /// `instance_separator`, since a detail message is always one string.
    fn render_template(&self, template: &'a str) -> String {
        match self.eval_template(template) {
            Ok(ExprResult::Str(s)) => s,
            Ok(ExprResult::StrVector(v)) => v.join(&self.output_formatter.instance_separator),
            Ok(other) => {
                error!(
                    "Output template evaluated to a non-textual result: {:?}",
                    other
                );
                String::new()
            }
            Err(err) => {
                error!("Error evaluating output template: {:?}", err);
                String::new()
            }
        }
    }

    /// Renders `output.instance`, if configured, for appending to the OK
    /// message. Returns `None` when unconfigured, so callers can skip the
    /// separator entirely rather than appending an empty segment.
    ///
    /// `instance_display: "single"` (the default) only shows this segment
    /// when the template resolves to exactly one instance: for a mode
    /// covering several instances (e.g. a multi-core CPU), repeating a
    /// per-instance breakdown on every OK check would be pure noise, so it
    /// is only worth stating when there is nothing to disambiguate.
    fn instances_text(&self) -> Option<String> {
        let template = self.output_formatter.instance.as_deref()?;
        match self.eval_template(template) {
            Ok(ExprResult::Str(s)) => Some(s),
            Ok(ExprResult::StrVector(v)) => {
                if self.output_formatter.instance_display == "single" && v.len() != 1 {
                    return None;
                }
                Some(v.join(&self.output_formatter.instance_separator))
            }
            Ok(other) => {
                error!(
                    "Output template evaluated to a non-textual result: {:?}",
                    other
                );
                None
            }
            Err(err) => {
                error!("Error evaluating output template: {:?}", err);
                None
            }
        }
    }
}

/// Renders a value with a fixed number of decimals when the metric
/// requests one (Perl-parity templates like `2.00 %`), falling back to
/// the trimmed-trailing-zeros default otherwise.
pub fn format_value(value: &f64, decimals: Option<usize>) -> String {
    match decimals {
        Some(n) => format!("{:.*}", n, value),
        None => float_string(value),
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

    #[test]
    fn fixed_decimals_are_honoured() {
        use super::format_value;

        assert_eq!(format_value(&2.0, Some(2)), "2.00");
        assert_eq!(format_value(&2.0, None), "2");
    }

    #[test]
    fn cpu_ok_message_appends_the_single_instance_detail() {
        use super::{ExprResult, Output, OutputFormatter, Perfdata, SnmpResult, Status};
        use std::collections::HashMap;

        let items = HashMap::from([
            ("metrics.cpu".to_string(), ExprResult::Vector(vec![2.0])),
            (
                "metrics.cpu.instance".to_string(),
                ExprResult::StrVector(vec!["0".to_string()]),
            ),
            (
                "aggregations.total_cpu_avg".to_string(),
                ExprResult::Number(2.0),
            ),
        ]);
        let collect = vec![SnmpResult::new(items)];
        let mut output = Output::new();
        output.ok =
            "OK: {Count(metrics.cpu)} CPU(s) average usage is {aggregations.total_cpu_avg:.2f} %"
                .to_string();
        output.instance =
            Some("CPU '{metrics.cpu.instance}' usage : {metrics.cpu:.2f} %".to_string());
        let metrics: Vec<Perfdata> = vec![];
        let formatter = OutputFormatter::new(Status::Ok, &collect, &metrics, &output);
        let result = formatter.to_string();
        assert_eq!(
            result,
            "OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | "
        );
    }

    #[test]
    fn warning_detail_uses_the_metric_output_template() {
        use super::{ExprResult, Output, OutputFormatter, Perfdata, SnmpResult, Status};
        use std::collections::HashMap;

        let items = HashMap::from([
            ("metrics.cpu".to_string(), ExprResult::Vector(vec![2.0])),
            (
                "metrics.cpu.instance".to_string(),
                ExprResult::StrVector(vec!["0".to_string()]),
            ),
        ]);
        let collect = vec![SnmpResult::new(items)];
        let output = Output::new();
        let m = Perfdata {
            name: "0#cpu".to_string(),
            value: 2.0,
            uom: "%",
            min: Some(0.0),
            max: Some(100.0),
            warning: Some("0:0".to_string()),
            critical: None,
            status: Some(Status::Warning),
            decimals: Some(2),
            output: Some("CPU '{metrics.cpu.instance}' usage : {metrics.cpu:.2f} %"),
            order: 1,
        };
        let metrics = vec![m];
        let formatter = OutputFormatter::new(Status::Warning, &collect, &metrics, &output);
        let result = formatter.to_string();
        assert!(result.starts_with("WARNING: CPU '0' usage : 2.00 % | "));
    }
}
