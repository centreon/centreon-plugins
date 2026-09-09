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
///
/// Uses `ureq::rustls` (ureq's own re-export, `pub use rustls;` in its
/// `lib.rs`) rather than a separately-versioned `rustls` dependency: with no
/// `Cargo.lock` committed for this crate (workspace convention, see
/// `rust-plugins/.gitignore`), a fresh resolve can pick a newer `ureq` built
/// against a newer `rustls` than one we'd pin ourselves, and `AgentBuilder::
/// tls_config` rejects a `ClientConfig` from a different `rustls` instance
/// even at the same semver-major version (0.21.x from us vs. 0.23.x already
/// pulled in by `ureq` - two distinct crate instances to the compiler).
/// Importing through `ureq::rustls` instead always matches whatever `ureq`
/// itself resolved to, so this can't drift out of sync again.
use ureq::rustls;

#[derive(Debug)]
struct NoCertVerification(rustls::crypto::CryptoProvider);

impl rustls::client::danger::ServerCertVerifier for NoCertVerification {
    fn verify_server_cert(
        &self,
        _end_entity: &rustls::pki_types::CertificateDer<'_>,
        _intermediates: &[rustls::pki_types::CertificateDer<'_>],
        _server_name: &rustls::pki_types::ServerName<'_>,
        _ocsp_response: &[u8],
        _now: rustls::pki_types::UnixTime,
    ) -> Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
        Ok(rustls::client::danger::ServerCertVerified::assertion())
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls12_signature(message, cert, dss, &self.0.signature_verification_algorithms)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls13_signature(message, cert, dss, &self.0.signature_verification_algorithms)
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        self.0.signature_verification_algorithms.supported_schemes()
    }
}

pub(crate) fn insecure_tls_config() -> rustls::ClientConfig {
    let provider = rustls::crypto::ring::default_provider();
    rustls::ClientConfig::builder_with_provider(std::sync::Arc::new(provider.clone()))
        .with_safe_default_protocol_versions()
        .expect("rustls default protocol versions are always valid")
        .dangerous()
        .with_custom_certificate_verifier(std::sync::Arc::new(NoCertVerification(provider)))
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
