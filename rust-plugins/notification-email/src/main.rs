//! Rust port of `notification::email::plugin` / `notification::email::mode::alert`:
//! composes a Centreon host/service/BAM/meta-service notification email
//! (with an optional inline performance-graph PNG) and sends it over SMTP.
//!
//! # Usage
//! See `Cli` in `cli.rs` for the full option list - every flag matches the
//! Perl mode's name and default so existing Centreon Engine notification
//! commands keep working unchanged.

mod cli;
mod graph;
mod mail;
mod message;
mod sparkline;
mod style;
mod template;

use clap::Parser;
use std::process::ExitCode;

fn main() -> ExitCode {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let args = match cli::Cli::parse().validate() {
        Ok(args) => args,
        Err(e) => {
            println!("UNKNOWN: {e}");
            return ExitCode::from(3);
        }
    };

    let notif = message::build(&args);

    match mail::send(&args, &notif) {
        Ok(()) => {
            println!("OK: Email sent");
            ExitCode::from(0)
        }
        Err(e) => {
            println!("UNKNOWN: {e}");
            ExitCode::from(3)
        }
    }
}
