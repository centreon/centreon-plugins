//! Entry point for the Centreon SNMP plugin.
//!
//! Parses CLI arguments (hostname, port, SNMP credentials, filters, thresholds),
//! loads a JSON command definition, runs the SNMP collection and metric computation,
//! and prints Nagios-compatible output to stdout.
//!
//! # Usage
//! ```text
//! plugin -H <host> -p <port> -j <config.json> [--warning-<metric> <value>] [--critical-<metric> <value>]
//! ```

extern crate env_logger;
extern crate lalrpop_util;
extern crate lexopt;
extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;
extern crate regex;
extern crate serde;
extern crate serde_json;
extern crate snafu;

mod compute;
mod generic;
mod output;
mod snmp;

use env_logger::Env;
use generic::Command;
use generic::Status;
use generic::error::*;
use lalrpop_util::lalrpop_mod;
use lexopt::Arg;
use log::trace;
use snmp::SnmpConfig;
use std::fs;

lalrpop_mod!(grammar);

/// Reads a JSON file and deserializes it into a [`Command`].
///
/// # Errors
/// Returns an error if the file cannot be read or if the JSON is malformed.
fn json_to_command(file_name: &str) -> Result<Command, Error> {
    // Transform content of the file into a string
    let configuration = fs::read_to_string(file_name)?;
    let command = serde_json::from_str(&configuration)?;
    Ok(command)
}

fn main() -> Result<(), Error> {
    match std::panic::catch_unwind(|| snmp_plugin()) {
        std::result::Result::Ok(plugin_result) => plugin_result,
        Err(e) => {
            let message = e
                .downcast_ref::<&str>()
                .map(|s| s.to_string())
                .or_else(|| e.downcast_ref::<String>().cloned())
                .unwrap_or_else(|| "unknown panic payload".to_string());
            println!(
                "Unexpected error : '{}' while executing the plugin, please use RUST_BACKTRACE=1 or PLUGIN_LOG=trace to find more information ",
                message
            );
            std::process::exit(3);
        }
    }
}

fn snmp_plugin() -> Result<(), Error> {
    env_logger::Builder::from_env(
        Env::default()
            .default_filter_or("info")
            .filter("PLUGIN_LOG"),
    )
    .init();

    use lexopt::prelude::*;
    let mut parser = lexopt::Parser::from_env();
    let mut hostname = "localhost".to_string();
    let mut port = 161;
    let mut snmp_version = "2c".to_string();
    let mut snmp_community = "public".to_string();
    // Mirrors of the Perl plugin options: --timeout (per-request receive
    // timeout, default 1s) and --snmp-retries (default 2, audit P9
    // recommendation rather than the Perl default of 5).
    let mut timeout_secs: u64 = 1;
    let mut snmp_retries: u32 = 2;
    // Global budget for the whole collection: exits with a clean UNKNOWN
    // before centengine (60s default) kills the process.
    let mut collect_timeout_secs: u64 = 50;
    let mut filter_in = Vec::new();
    let mut filter_out = Vec::new();
    let mut no_data_status = Status::Unknown;
    let mut check_format = false;
    let mut check_response = false;
    let mut list_counters = false;
    let mut json_file: Option<String> = None;
    let mut cmd: Option<Command> = None;
    let mut warnings: Vec<(String, String)> = Vec::new();
    let mut criticals: Vec<(String, String)> = Vec::new();
    loop {
        let arg = parser.next();
        match arg {
            Ok(arg) => match arg {
                Some(arg) => match arg {
                    Short('H') | Long("hostname") => {
                        hostname = parser.value()?.into_string()?;
                        trace!("hostname: {:}", hostname);
                    }
                    Short('p') | Long("port") => {
                        port = parser.value()?.parse::<u16>()?;
                        trace!("port: {}", port);
                    }
                    Short('j') | Long("json") => {
                        let json = parser.value()?.into_string()?;
                        json_file = Some(json);
                        trace!("json file: {:?}", json_file);
                    }
                    Short('v') | Long("snmp-version") => {
                        snmp_version = parser.value()?.into_string()?;
                        trace!("snmp_version: {}", snmp_version);
                    }
                    Short('c') | Long("snmp-community") => {
                        /// For backward compatibility 'public' is used when the SNMP community is empty
                        let s = parser.value()?.into_string()?;
                        if !s.is_empty() {
                            snmp_community = s;
                            trace!("snmp_community: {}", snmp_community);
                        }
                    }
                    Short('i') | Long("filter-in") => {
                        let f = parser.value()?.into_string()?;
                        trace!("New filter_in: {}", f);
                        filter_in.push(f);
                    }
                    Short('o') | Long("filter-out") => {
                        let f = parser.value()?.into_string()?;
                        trace!("New filter_out: {}", f);
                        filter_out.push(f);
                    }
                    Long("no-data-status") => {
                        let s = parser.value()?.into_string()?;
                        no_data_status = s.parse::<Status>().unwrap_or_else(|e| {
                            println!("UNKNOWN: {}", e);
                            std::process::exit(3);
                        });
                        trace!("no_data_status: {:?}", no_data_status);
                    }
                    Short('h') | Long("help") => {
                        let prog = std::env::args()
                            .next()
                            .unwrap_or_else(|| "plugin".to_string());
                        println!("Usage: {} [OPTIONS]\n", prog);
                        println!("OPTIONS:");
                        println!("  -H, --hostname <HOST>            Hostname or IP address (default: localhost)");
                        println!("  -p, --port <PORT>                SNMP port (default: 161)");
                        println!("  -v, --snmp-version <VERSION>     SNMP version (default: 2c)");
                        println!("  -c, --snmp-community <COMMUNITY> SNMP community (default: public)");
                        println!("  -j, --json <FILE>                JSON command definition file (required)");
                        println!("  -i, --filter-in <FILTER>         Include filter (can be used multiple times)");
                        println!("  -o, --filter-out <FILTER>        Exclude filter (can be used multiple times)");
                        println!("  --no-data-status <STATUS>        Status when the filters keep no data: OK, WARNING, CRITICAL or UNKNOWN (default: UNKNOWN)");
                        println!("  --timeout <SECONDS>              Timeout per SNMP request attempt (default: 1)");
                        println!("  --snmp-retries <COUNT>           Retries after a timed-out attempt (default: 2)");
                        println!("  --collect-timeout <SECONDS>      Global time budget for the whole collection (default: 50)");
                        println!("  --warning-<METRIC> <VALUE>       Warning threshold for metric");
                        println!("  --critical-<METRIC> <VALUE>      Critical threshold for metric");
                        println!("  --check-format                   Check JSON file validity and exit");
                        println!("  --check-response                 Display raw SNMP response");
                        println!("  --list-counters                  List all available metrics");
                        println!("  -h, --help                       Print this help message");
                        std::process::exit(0);
                    }
                    Long("timeout") => {
                        timeout_secs = parser.value()?.parse::<u64>()?;
                        trace!("timeout: {}s", timeout_secs);
                    }
                    Long("snmp-retries") => {
                        snmp_retries = parser.value()?.parse::<u32>()?;
                        trace!("snmp_retries: {}", snmp_retries);
                    }
                    Long("collect-timeout") => {
                        collect_timeout_secs = parser.value()?.parse::<u64>()?;
                        trace!("collect_timeout: {}s", collect_timeout_secs);
                    }
                    Long("check-format") => {
                        check_format = true;
                    }
                    Long("check-response") => {
                        check_response = true;
                    }
                    Long("list-counters") => {
                        list_counters = true;
                    }
                    t => {
                        match t {
                            Arg::Long(name) if name.starts_with("warning-") => {
                                let wmetric = name[8..].to_string();
                                let value = parser.value()?.into_string()?;
                                if !value.is_empty() {
                                    trace!("Warning stored for metric '{}'", wmetric);
                                    warnings.push((wmetric, value));
                                }
                            }
                            Arg::Long(name) if name.starts_with("critical-") => {
                                let cmetric = name[9..].to_string();
                                let value = parser.value()?.into_string()?;
                                if !value.is_empty() {
                                    trace!("Critical stored for metric '{}'", cmetric);
                                    criticals.push((cmetric, value));
                                }
                            }
                            Arg::Long(name) => {
                                return Err(Error::UnknownArgument {
                                    arg: format!("--{}", name),
                                });
                            }
                            Arg::Short(c) => {
                                return Err(Error::UnknownArgument {
                                    arg: format!("-{}", c),
                                });
                            }
                            _ => {}
                        }
                    }
                },
                None => {
                    break;
                }
            },
            Err(err) => {
                println!("Error: {}", err);
                std::process::exit(1);
            }
        }
    }
    if let Some(file) = json_file {
        if check_format {
            println!("Check format of JSON file '{}'", file);
        }
        match json_to_command(&file) {
            Ok(c) => {
                cmd = Some(c);
            }
            Err(e) => {
                if check_format {
                    println!("JSON is INVALID: {}", e);
                    std::process::exit(3);
                } else {
                    println!("UNKNOWN: Cannot read JSON file '{}': {}", file, e);
                    std::process::exit(3);
                }
            }
        }
    } else {
        println!("JSON file is required (use -j or --json argument)");
        std::process::exit(3);
    }
    if let Some(ref mut cmd) = cmd {
        for (metric, value) in warnings {
            cmd.add_warning(&metric, value);
        }
        for (metric, value) in criticals {
            cmd.add_critical(&metric, value);
        }
    }

    let cmd = match cmd {
        Some(cmd) => cmd,
        None => {
            println!("UNKNOWN: JSON is empty");
            std::process::exit(3);
        }
    };

    if list_counters {
        cmd.list_counters();
        std::process::exit(0);
    }

    let snmp_config = SnmpConfig {
        target: format!("{}:{}", hostname, port),
        version: snmp_version,
        community: snmp_community,
        timeout: std::time::Duration::from_secs(timeout_secs),
        retries: snmp_retries,
        collect_timeout: std::time::Duration::from_secs(collect_timeout_secs),
    };

    let result = cmd.execute(
        &snmp_config,
        &filter_in,
        &filter_out,
        check_format,
        check_response,
        no_data_status,
    ).unwrap_or_else(|e| {
        if check_format {
            println!("JSON is INVALID: {}", e);
        } else {
            println!("UNKNOWN: {}", e);
        }
        std::process::exit(3);
    });

    if check_format {
        println!("JSON is valid");
    } else {
        println!("{}", result.output);
        std::process::exit(result.status.into());
    }

    Ok(())
}
