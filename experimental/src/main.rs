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
use generic::error::*;
use lalrpop_util::lalrpop_mod;
use lexopt::Arg;
use log::trace;
use std::fs;

lalrpop_mod!(grammar);

fn json_to_command(file_name: &str) -> Result<Command, Error> {
    // Transform content of the file into a string
    let configuration = fs::read_to_string(file_name)?;
    let command = serde_json::from_str(&configuration)?;
    Ok(command)
}

#[snafu::report]
fn main() -> Result<(), Error> {
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
    let mut filter_in = Vec::new();
    let mut filter_out = Vec::new();
    let mut cmd: Option<Command> = None;
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
                        trace!("json: {:?}", json);
                        cmd = Some(json_to_command(&json)?);
                    }
                    Short('v') | Long("snmp-version") => {
                        snmp_version = parser.value()?.into_string()?;
                        trace!("snmp_version: {}", snmp_version);
                    }
                    Short('c') | Long("snmp-community") => {
                        snmp_community = parser.value()?.into_string()?;
                        trace!("snmp_community: {}", snmp_community);
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
                    t => {
                        if let Arg::Long(name) = t {
                            if name.starts_with("warning-") {
                                let wmetric = name[8..].to_string();
                                let value = parser.value()?.into_string()?;
                                match cmd.as_mut() {
                                    Some(ref mut cmd) => {
                                        if !value.is_empty() {
                                            cmd.add_warning(&wmetric, value);
                                        } else {
                                            trace!("Warning metric '{}' is empty", wmetric);
                                        }
                                    }
                                    None => {
                                        println!("json is empty");
                                        std::process::exit(3);
                                    }
                                }
                            } else if name.starts_with("critical-") {
                                let cmetric = name[9..].to_string();
                                let value = parser.value()?.into_string()?;
                                match cmd.as_mut() {
                                    Some(ref mut cmd) => {
                                        if !value.is_empty() {
                                            cmd.add_critical(&cmetric, value);
                                        } else {
                                            trace!("Critical metric '{}' is empty", cmetric);
                                        }
                                    }
                                    None => {
                                        println!("json is empty");
                                        std::process::exit(3);
                                    }
                                }
                            }
                        }
                    }
                },
                None => {
                    break;
                }
            },
            Err(err) => {
                println!("err: {:?}", err);
                std::process::exit(3);
            }
        }
    }
    let url = format!("{}:{}", hostname, port);

    let result = match cmd {
        Some(ref cmd) => cmd.execute(
            &url,
            &snmp_version,
            &snmp_community,
            &filter_in,
            &filter_out,
        )?,
        None => {
            println!("json is empty");
            std::process::exit(3);
        }
    };

    println!("{}", result.output);
    Ok(())
}
