extern crate clap;
extern crate log;
extern crate rasn;
extern crate rasn_smi;
extern crate rasn_snmp;
extern crate regex;
extern crate serde;
extern crate serde_json;

mod lib;
mod generic;

use clap::Parser;
use lib::r_snmp_get;
use serde_json::Result;
use std::fs;
use generic::{Command};

#[derive(Parser, Debug)]
#[command(version, about)]
struct Cli {
    /// Hostname to operate on
    #[arg(long, short='H')]
    hostname: String,

    #[arg(long, short, default_value_t = 161)]
    port: u16,

    #[arg(long, short='v')]
    snmp_version: String,

    #[arg(long, short)]
    community: String,

    #[arg(long, short)]
    json_conf: String,
}

fn json_to_command(file_name: &str) -> Result<Command> {

    // Transform content of the file into a string
    let contents = match fs::read_to_string(file_name)
     {
        Ok(ret) => ret,
        Err(err) => panic!("Could not deserialize the file, error code: {}", err)
    };

    let module: Result<Command> = serde_json::from_str(&contents.as_str());
    module
}

fn main() {
    let cli = Cli::parse();
    let url = format!("{}:{}", cli.hostname, cli.port);
    let cmd = json_to_command(&cli.json_conf);
    let cmd = cmd.unwrap();
    let result = cmd.execute(&url);
    println!("{}", result.output);
    std::process::exit(result.status);
}
