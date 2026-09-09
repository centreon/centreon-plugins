//! Fetches the performance-graph PNG from the Centreon web UI's
//! `generateImage.php` endpoint, mirroring the `$self->{http}->request(...)`
//! call in `service_message`/`metaservice_message` in `alert.pm`.

use std::io::Read;
use std::time::Duration;

pub enum GraphOutcome {
    /// `--centreon-user`/`--centreon-token` were not both provided: the Perl
    /// mode skips the request entirely and leaves `$graph_html` undefined.
    NotConfigured,
    /// Non-200 response, or a 200 response whose body starts with "OK"
    /// (`generateImage.php`'s way of saying it has nothing to draw).
    NoGraph,
    /// A 200 response containing one of the known error strings.
    Error(String),
    Found(Vec<u8>),
}

pub fn fetch(url: &str, timeout_secs: u64, insecure: bool) -> GraphOutcome {
    let mut builder = ureq::AgentBuilder::new().timeout(Duration::from_secs(timeout_secs));
    if insecure {
        builder = builder.tls_config(std::sync::Arc::new(insecure_tls_config()));
    }
    let agent = builder.build();

    let response = match agent.get(url).call() {
        Ok(r) => r,
        Err(e) => {
            log::warn!("graph fetch failed for {url}: {e}");
            return GraphOutcome::NoGraph;
        }
    };

    if response.status() != 200 {
        return GraphOutcome::NoGraph;
    }

    let mut bytes = Vec::new();
    if response.into_reader().read_to_end(&mut bytes).is_err() {
        return GraphOutcome::NoGraph;
    }

    if bytes.starts_with(b"OK") {
        return GraphOutcome::NoGraph;
    }
    if let Ok(text) = std::str::from_utf8(&bytes)
        && (text.contains("Access denied") || text.contains("Resource not found") || text.contains("Invalid token"))
    {
        return GraphOutcome::Error(text.to_string());
    }

    GraphOutcome::Found(bytes)
}

/// A rustls `ServerCertVerifier` that accepts any certificate, for `--insecure`
/// - mirrors the Perl mode's `--insecure` (Net::SSLeay `SSL_VERIFY_NONE`),
/// needed when `--centreon-url` points at a host with a self-signed or
/// internal-CA certificate the container's trust store doesn't carry.
struct NoCertVerification;

impl rustls::client::ServerCertVerifier for NoCertVerification {
    fn verify_server_cert(
        &self,
        _end_entity: &rustls::Certificate,
        _intermediates: &[rustls::Certificate],
        _server_name: &rustls::ServerName,
        _scts: &mut dyn Iterator<Item = &[u8]>,
        _ocsp_response: &[u8],
        _now: std::time::SystemTime,
    ) -> Result<rustls::client::ServerCertVerified, rustls::Error> {
        Ok(rustls::client::ServerCertVerified::assertion())
    }
}

pub(crate) fn insecure_tls_config() -> rustls::ClientConfig {
    rustls::ClientConfig::builder()
        .with_safe_defaults()
        .with_custom_certificate_verifier(std::sync::Arc::new(NoCertVerification))
        .with_no_client_auth()
}

/// Renders the `<img>`/error/placeholder markup that replaces `graphHtml` in
/// the service and meta-service templates.
pub fn graph_html(outcome: &GraphOutcome, cid: &str) -> String {
    match outcome {
        GraphOutcome::NotConfigured => String::new(),
        GraphOutcome::NoGraph => "<p>No graph found</p>".to_string(),
        GraphOutcome::Error(msg) => format!("<p>Cannot retrieve graph: {}</p>", msg),
        GraphOutcome::Found(_) => format!(
            "<img src=\"cid:{}\"  alt=\"Service Graph\" style=\"width:100%; height:auto;\">\n",
            cid
        ),
    }
}
