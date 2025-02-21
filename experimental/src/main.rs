extern crate clap;
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
use lib::r_snmp_get;
use serde_json::Result;
use std::fs;

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
        Err(err) => panic!("Could not deserialize the file, error code: {}", err),
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
    let result = cmd.execute(&url, &cli.community, &ext);
    println!("{}", result.output);
    std::process::exit(result.status);
}
