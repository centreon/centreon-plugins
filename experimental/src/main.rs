extern crate lexopt;
extern crate lalrpop_util;
extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;
extern crate regex;
extern crate serde;
extern crate serde_json;

mod generic;
mod snmp;

use generic::{Command, CommandExt};
use std::ffi::{OsString, OsStr};
use lalrpop_util::lalrpop_mod;
use snmp::r_snmp_get;
use serde_json::Result;
use std::fs;

lalrpop_mod!(grammar);

#[derive(Debug)]
//#[command(version, about)]
struct Cli {
    /// Hostname to operate on
    //#[arg(long, short = 'H', default_value = "localhost")]
    hostname: String,

    //#[arg(long, short, default_value_t = 161)]
    port: u16,

    //#[arg(long, short = 'v', default_value = "2c")]
    snmp_version: String,

    //#[arg(long, short, default_value = "public")]
    community: String,

    //#[arg(long, short)]
    json_conf: String,

    //#[arg(long, short)]
    warning_core: Option<String>,

    //#[arg(long, short = 'C')]
    critical_core: Option<String>,

    //#[arg(long, short = 'a')]
    warning_agregation: Option<String>,

    //#[arg(long, short = 'b')]
    critical_agregation: Option<String>,
}

fn json_to_command(file_name: &str) -> Result<Command> {
    // Transform content of the file into a string
    let contents = match fs::read_to_string(file_name) {
        Ok(ret) => ret,
        Err(err) => {
            println!("erreur: {}", err);
            std::process::exit(3);
        }
    };

    let module: Result<Command> = serde_json::from_str(&contents.as_str());
    module
}

fn main() {
    use lexopt::prelude::*;
    let mut parser = lexopt::Parser::from_env();
    let mut hostname = "localhost".to_string();
    let mut port = 161;
    let mut snmp_version = "2c".to_string();
    let mut snmp_community = "public".to_string();
    let mut json = None;
    loop {
        let arg = parser.next();
        match arg {
            Ok(arg) => {
                println!("{:?} ok", arg);
                match arg {
                    Some(arg) => {
                        match arg {
                            Short('H') | Long("hostname") => {
                                hostname = parser.value().unwrap().into_string().unwrap();
                            },
                            Short('p') | Long("port") => {
                                port = parser.value().unwrap().parse::<u16>().unwrap();
                                println!("port: {}", port);
                            },
                            Short('j') | Long("json") => {
                                json = Some(parser.value().unwrap().into_string().unwrap());
                                println!("json: {:?}", json);
                            },
                            Short('v') | Long("snmp-version") => {
                                snmp_version = parser.value().unwrap().into_string().unwrap();
                                println!("snmp_version: {}", snmp_version);
                            },
                            Short('c') | Long("snmp-community") => {
                                snmp_community = parser.value().unwrap().into_string().unwrap();
                                println!("snmp_community: {}", snmp_community);
                            },
                            _ => {
                                println!("other");
                            }
                        }
                    },
                    None => {
                        break;
                    }
                }
            },
            Err(err) => {
                println!("err: {:?}", err);
                std::process::exit(3);
            }
        }
    }
    let url = format!("{}:{}", hostname, port);

    if json.is_none() {
        println!("json is empty");
        std::process::exit(3);
    }

    let json = json.unwrap();
    let cmd = json_to_command(&json);
    let cmd = cmd.unwrap();
    //let ext = CommandExt {
    //    warning_core: cli.warning_core,
    //    critical_core: cli.critical_core,
    //    warning_agregation: cli.warning_agregation,
    //    critical_agregation: cli.critical_agregation,
    //};
    let result = cmd.execute(&url, &snmp_version, &snmp_community);
    //println!("{}", result.output);
    //std::process::exit(result.status as i32);
}

mod Test {
    use super::*;

    #[test]
    fn term() {
        assert!(grammar::TermParser::new().parse("132").is_ok());
        assert!(grammar::TermParser::new().parse("((132))").is_ok());
        assert!(grammar::TermParser::new().parse("((132)))").is_err());
    }

    #[test]
    fn sum() {
        let res = grammar::SumParser::new().parse("1 + 2");
        assert!(res.is_ok());
        assert!(res.unwrap() == 3_f32);
        let res = grammar::SumParser::new().parse("1 + 2 + 3");
        assert!(res.is_ok());
        assert!(res.unwrap() == 6_f32);
        let res = grammar::SumParser::new().parse("1 - 2 + 3");
        assert!(res.is_ok());
        assert!(res.unwrap() == 2_f32);
        let res = grammar::SumParser::new().parse("1 + 2 - 3");
        assert!(res.is_ok());
        assert!(res.unwrap() == 0_f32);
    }

    #[test]
    fn product() {
        let res = grammar::ProductParser::new().parse("2 * 3");
        assert!(res.is_ok());
        assert!(res.unwrap() == 6_f32);

        let res = grammar::ProductParser::new().parse("2 * 3 * 4");
        assert!(res.is_ok());
        assert!(res.unwrap() == 24_f32);

        let res = grammar::ProductParser::new().parse("2 * 3 / 2");
        assert!(res.is_ok());
        assert!(res.unwrap() == 3_f32);

        //        let res = grammar::ProductParser::new().parse("2 / 0");
        //        assert!(res.is_err());
    }

    #[test]
    fn sum_product() {
        let res = grammar::SumParser::new().parse("1 + 2 * 3");
        assert!(res.is_ok());
        assert!(res.unwrap() == 7_f32);

        let res = grammar::SumParser::new().parse("1 + (3 + 2 * 3) / 3");
        assert!(res.is_ok());
        assert!(res.unwrap() == 4_f32);
    }

    #[test]
    fn function() {
        let res = grammar::TermParser::new().parse("Average(1, 2, 3)");
        assert!(res.is_ok());
        assert!(res.unwrap() == 2_f32);

        let res = grammar::TermParser::new().parse("Average(1 + 2 * 2, 3, 4)");
        assert!(res.is_ok());
        assert!(res.unwrap() == 4_f32);
    }
}
