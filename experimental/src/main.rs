extern crate clap;
extern crate lalrpop_util;
extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;
extern crate regex;
extern crate serde;
extern crate serde_json;

mod generic;
mod lib;

use clap::Parser;
use generic::{Command, CommandExt};
use lalrpop_util::lalrpop_mod;
use lib::r_snmp_get;
use serde_json::Result;
use std::fs;

lalrpop_mod!(grammar);

#[derive(Parser, Debug)]
#[command(version, about)]
struct Cli {
    /// Hostname to operate on
    #[arg(long, short = 'H', default_value = "localhost")]
    hostname: String,

    #[arg(long, short, default_value_t = 161)]
    port: u16,

    #[arg(long, short = 'v', default_value = "2c")]
    snmp_version: String,

    #[arg(long, short, default_value = "public")]
    community: String,

    #[arg(long, short)]
    json_conf: String,

    #[arg(long, short)]
    warning_core: Option<String>,

    #[arg(long, short = 'C')]
    critical_core: Option<String>,

    #[arg(long, short = 'a')]
    warning_agregation: Option<String>,

    #[arg(long, short = 'b')]
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
    let cli = Cli::parse();
    let url = format!("{}:{}", cli.hostname, cli.port);
    let cmd = json_to_command(&cli.json_conf);
    let cmd = cmd.unwrap();
    let ext = CommandExt {
        warning_core: cli.warning_core,
        critical_core: cli.critical_core,
        warning_agregation: cli.warning_agregation,
        critical_agregation: cli.critical_agregation,
    };
    let result = cmd.execute(&url, &cli.snmp_version, &cli.community, &ext);
    println!("{}", result.output);
    std::process::exit(result.status as i32);
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
