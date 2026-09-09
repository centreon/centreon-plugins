pub mod bam;
pub mod host;
pub mod metaservice;
pub mod service;

use crate::cli::Args;

pub struct Notification {
    pub subject: String,
    pub alt_message: String,
    pub html_message: String,
    pub graph_png: Option<Vec<u8>>,
    pub graph_cid: Option<String>,
}

enum Kind {
    Host,
    Service,
    Bam,
    MetaService,
}

/// Same dispatch as `set_payload` in `alert.pm`: BAM and meta-service are
/// detected from the synthetic `_Module_BAM`/`_Module_Meta` host name Centreon
/// Engine uses for those pseudo-hosts; anything else with a non-empty
/// `--service-description` is a service notification, otherwise a host one.
fn classify(host_name: &str, service_description: Option<&str>) -> Kind {
    if host_name.starts_with("_Module_BAM") {
        Kind::Bam
    } else if host_name.starts_with("_Module_Meta") {
        Kind::MetaService
    } else if service_description.is_some_and(|s| !s.is_empty()) {
        Kind::Service
    } else {
        Kind::Host
    }
}

pub fn build(args: &Args) -> Notification {
    let host_name = args.raw.host_name.as_deref().unwrap_or_default();
    let service_description = args.raw.service_description.as_deref();
    match classify(host_name, service_description) {
        Kind::Bam => bam::render(args),
        Kind::MetaService => metaservice::render(args),
        Kind::Service => service::render(args),
        Kind::Host => host::render(args),
    }
}

/// Author/comment/event-type resolution shared verbatim by all four
/// `*_message` subs in `alert.pm`.
pub struct EventContext {
    pub event_type: String,
    pub author: String,
    pub author_alt: String,
    pub comment: String,
    pub comment_alt: String,
    pub include_author: bool,
    pub include_comment: bool,
}

/// Reproduces `alert.pm`'s `/^flaping.*$/i` verbatim, including its missing
/// second "p" — changing it would silently alter which notification types
/// get an event-type label, so any fix belongs in a follow-up, not this port.
fn event_label(notif_type: &str) -> Option<&'static str> {
    let lower = notif_type.to_lowercase();
    if lower.starts_with("downtime") {
        Some("Scheduled Downtime")
    } else if lower == "acknowledgement" {
        Some("Acknowledged")
    } else if lower.starts_with("flaping") {
        Some("Flapping")
    } else {
        None
    }
}

pub fn event_context(
    notif_type: &str,
    notif_author: Option<&str>,
    notif_comment: Option<&str>,
) -> EventContext {
    let mut ctx = EventContext {
        event_type: String::new(),
        author: String::new(),
        author_alt: String::new(),
        comment: String::new(),
        comment_alt: String::new(),
        include_author: false,
        include_comment: false,
    };

    if let Some(author) = notif_author.filter(|a| !a.is_empty()) {
        ctx.include_author = true;
        ctx.author = author.to_string();
        if let Some(label) = event_label(notif_type) {
            ctx.event_type = label.to_string();
            ctx.author_alt = format!("{} by: {}", label, author);
        }
    }

    if let Some(comment) = notif_comment.filter(|c| !c.is_empty()) {
        ctx.include_comment = true;
        ctx.comment = comment.to_string();
        if let Some(label) = event_label(notif_type) {
            ctx.event_type = label.to_string();
            ctx.comment_alt = format!("{} Comment: {}", label, comment);
        }
    }

    ctx
}

/// Builds the `dynamicHref` "More Information" link: a `centreon-url` +
/// `url-path` base, followed by a `?details=` query param carrying
/// URL-encoded JSON, exactly as every `*_message` sub does via
/// `encode_json`/`uri_escape`.
pub fn dynamic_href(args: &Args, id: &str, endpoint_suffix: &str, tab: &str) -> String {
    let raw = &args.raw;
    let details = serde_json::json!({
        "id": id,
        "resourcesDetailsEndpoint": format!("{}{}", raw.url_path, endpoint_suffix),
        "tab": tab,
    });
    format!(
        "{}{}/monitoring/resources?details={}",
        raw.centreon_url.as_deref().unwrap_or_default(),
        raw.url_path,
        urlencoding::encode(&details.to_string())
    )
}
