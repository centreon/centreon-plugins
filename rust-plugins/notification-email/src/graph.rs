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

pub fn fetch(url: &str, timeout_secs: u64) -> GraphOutcome {
    let agent = ureq::AgentBuilder::new()
        .timeout(Duration::from_secs(timeout_secs))
        .build();

    let response = match agent.get(url).call() {
        Ok(r) => r,
        Err(_) => return GraphOutcome::NoGraph,
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
