//! CLI options, kept name-for-name and default-for-default with
//! `notification::email::mode::alert` so existing Centreon Engine notification
//! command definitions (built around `$HOSTNAME$`, `$CONTACTEMAIL$`, etc.)
//! keep working unchanged against this binary.

use clap::Parser;

#[derive(Parser, Debug)]
#[command(name = "centreon-plugin-notification-email", about = "Send Centreon email notifications")]
pub struct Cli {
    #[arg(long)]
    pub smtp_address: Option<String>,
    #[arg(long, default_value = "25")]
    pub smtp_port: String,
    #[arg(long)]
    pub smtp_user: Option<String>,
    #[arg(long)]
    pub smtp_password: Option<String>,
    #[arg(long)]
    pub smtp_nossl: bool,
    #[arg(long)]
    pub smtp_debug: bool,

    #[arg(long)]
    pub to_address: Option<String>,
    #[arg(long)]
    pub from_address: Option<String>,

    #[arg(long)]
    pub host_id: Option<String>,
    #[arg(long)]
    pub host_address: Option<String>,
    #[arg(long)]
    pub host_name: Option<String>,
    #[arg(long)]
    pub host_alias: Option<String>,
    #[arg(long)]
    pub host_state: Option<String>,
    #[arg(long)]
    pub host_output: Option<String>,
    #[arg(long)]
    pub host_attempts: Option<String>,
    #[arg(long)]
    pub max_host_attempts: Option<String>,
    #[arg(long)]
    pub host_duration: Option<String>,

    #[arg(long)]
    pub service_id: Option<String>,
    #[arg(long)]
    pub service_description: Option<String>,
    #[arg(long)]
    pub service_displayname: Option<String>,
    #[arg(long)]
    pub service_state: Option<String>,
    #[arg(long)]
    pub service_output: Option<String>,
    #[arg(long)]
    pub service_longoutput: Option<String>,
    #[arg(long)]
    pub service_attempts: Option<String>,
    #[arg(long)]
    pub max_service_attempts: Option<String>,
    #[arg(long)]
    pub service_duration: Option<String>,

    #[arg(long)]
    pub centreon_url: Option<String>,
    #[arg(long, default_value = "/centreon")]
    pub url_path: String,
    #[arg(long)]
    pub centreon_user: Option<String>,
    #[arg(long)]
    pub centreon_token: Option<String>,

    #[arg(long)]
    pub date: Option<String>,
    #[arg(long)]
    pub notif_author: Option<String>,
    #[arg(long)]
    pub notif_comment: Option<String>,
    #[arg(long = "type")]
    pub notif_type: Option<String>,

    #[arg(long, default_value_t = 10)]
    pub timeout: u64,
}

/// Options after the same required-field checks `check_options` performs in
/// the Perl mode, with defaults resolved (e.g. `url_path` always leading-slash).
pub struct Args {
    pub raw: Cli,
}

#[derive(Debug)]
pub struct MissingOption(pub &'static str);

impl std::fmt::Display for MissingOption {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "You need to specify --{} option.", self.0)
    }
}

impl Cli {
    /// Validates required options and normalizes `url_path`, mirroring
    /// `check_options` in `alert.pm` (same option names, same error text).
    pub fn validate(mut self) -> Result<Args, MissingOption> {
        require(&self.to_address, "to-address")?;
        require(&self.host_name, "host-name")?;
        require(&self.smtp_address, "smtp-address")?;

        if !self.url_path.starts_with('/') {
            self.url_path = format!("/{}", self.url_path);
        }

        Ok(Args { raw: self })
    }
}

fn require(value: &Option<String>, flag: &'static str) -> Result<(), MissingOption> {
    match value {
        Some(v) if !v.is_empty() => Ok(()),
        _ => Err(MissingOption(flag)),
    }
}
