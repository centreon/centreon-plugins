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
mod snmp;

use generic::error::*;
use generic::Command;
use lalrpop_util::lalrpop_mod;
use lexopt::Arg;
use log::{debug, trace};
use snafu::ResultExt;
use std::fs;

lalrpop_mod!(grammar);

fn json_to_command(file_name: &str) -> Result<Command, Error> {
    // Transform content of the file into a string
    let contents = fs::read_to_string(file_name).context(JsonReadSnafu { path: file_name })?;

    let content = contents.as_str();

    let module: serde_json::Result<Command> = serde_json::from_str(content);
    match module {
        Ok(c) => Ok(c),
        Err(err) => Err(Error::JsonParse {
            message: err.to_string(),
        }),
    }
}

fn main() -> Result<(), Error> {
    env_logger::init();

    use lexopt::prelude::*;
    let mut parser = lexopt::Parser::from_env();
    let mut hostname = "localhost".to_string();
    let mut port = 161;
    let mut snmp_version = "2c".to_string();
    let mut snmp_community = "public".to_string();
    let mut cmd: Option<Command> = None;
    loop {
        let arg = parser.next();
        match arg {
            Ok(arg) => match arg {
                Some(arg) => match arg {
                    Short('H') | Long("hostname") => {
                        hostname = parser.value().unwrap().into_string().unwrap();
                        trace!("hostname: {:}", hostname);
                    }
                    Short('p') | Long("port") => {
                        port = parser.value().unwrap().parse::<u16>().unwrap();
                        trace!("port: {}", port);
                    }
                    Short('j') | Long("json") => {
                        let json = Some(parser.value().unwrap().into_string().unwrap());
                        let json = json.unwrap();
                        trace!("json: {:?}", json);
                        cmd = Some(json_to_command(&json)?);
                    }
                    Short('v') | Long("snmp-version") => {
                        snmp_version = parser.value().unwrap().into_string().unwrap();
                        trace!("snmp_version: {}", snmp_version);
                    }
                    Short('c') | Long("snmp-community") => {
                        snmp_community = parser.value().unwrap().into_string().unwrap();
                        trace!("snmp_community: {}", snmp_community);
                    }
                    t => {
                        if let Arg::Long(name) = t {
                            if name.starts_with("warning-") {
                                let wmetric = name[8..].to_string();
                                let value = parser.value().unwrap().into_string().unwrap();
                                match cmd.as_mut() {
                                    Some(ref mut cmd) => {
                                        cmd.add_warning(&wmetric, value);
                                    }
                                    None => {
                                        println!("json is empty");
                                        std::process::exit(3);
                                    }
                                }
                            } else if name.starts_with("critical-") {
                                let cmetric = name[9..].to_string();
                                let value = parser.value().unwrap().into_string().unwrap();
                                match cmd.as_mut() {
                                    Some(ref mut cmd) => {
                                        cmd.add_critical(&cmetric, value);
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
        Some(ref cmd) => cmd.execute(&url, &snmp_version, &snmp_community)?,
        None => {
            println!("json is empty");
            std::process::exit(3);
        }
    };

    //println!("{}", result.output);
    //std::process::exit(result.status as i32);
    Ok(())
}
