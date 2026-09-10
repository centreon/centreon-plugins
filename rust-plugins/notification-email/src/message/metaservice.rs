//! Port of `metaservice_message` in `alert.pm`.

use super::{dynamic_href, event_context, Notification};
use crate::cli::Args;
use crate::graph::{self, GraphOutcome};
use crate::sparkline::{self, SparklineOutcome};
use crate::style;
use crate::template::Template;

const TEMPLATE: &str = include_str!("../templates/metaservice.html");

pub fn render(args: &Args) -> Notification {
    let raw = &args.raw;
    let notif_type = raw.notif_type.as_deref().unwrap_or_default();
    let host_id = raw.host_id.as_deref().unwrap_or_default();
    let service_id = raw.service_id.as_deref().unwrap_or_default();
    let host_name = raw.host_name.as_deref().unwrap_or_default();
    let service_description = raw.service_description.as_deref().unwrap_or_default();
    let service_displayname = raw.service_displayname.as_deref().unwrap_or_default();
    let service_state = raw.service_state.as_deref().unwrap_or_default();
    let service_output = raw.service_output.as_deref().unwrap_or_default();
    let date = raw.date.as_deref().unwrap_or_default();

    let ctx = event_context(notif_type, raw.notif_author.as_deref(), raw.notif_comment.as_deref());

    // The Perl source builds the same CID (`hostname_servicedescription`) as
    // the service template even here, where `service_description` is usually
    // empty for a meta-service alert - reproduced as-is.
    let cid = format!("{host_name}_{service_description}");
    let (graph_html, graph_png) = if raw.api_token.as_deref().filter(|t| !t.is_empty()).is_some() {
        let outcome = sparkline::fetch(
            raw.centreon_url.as_deref().unwrap_or_default(),
            &raw.url_path,
            raw.api_token.as_deref(),
            host_id,
            service_id,
            raw.timeout,
            raw.insecure,
        );
        match outcome {
            SparklineOutcome::NotConfigured => (String::new(), None),
            SparklineOutcome::Error(msg) => (format!("<p>Cannot retrieve chart: {msg}</p>"), None),
            SparklineOutcome::Found(bytes) => (
                format!("<img src=\"cid:{cid}\"  alt=\"Service Graph\" style=\"width:100%; height:auto;\">\n"),
                Some(bytes),
            ),
        }
    } else {
        let outcome = fetch_graph(args, host_id, service_id);
        let html = graph::graph_html(&outcome, &cid);
        let png = match outcome {
            GraphOutcome::Found(bytes) => Some(bytes),
            _ => None,
        };
        (html, png)
    };

    let href = dynamic_href(
        args,
        service_id,
        &format!("/api/latest/monitoring/resources/hosts/{host_id}/services/{service_id}"),
        "details",
    );

    let subject = format!("*** {notif_type} Meta Service: {service_displayname} {service_state} ***");

    let mut alt_message = format!(
        "\n        ***** Centreon *****\n\n        Notification Type: {notif_type}\n        Meta Service: {service_displayname}\n        State: {service_state}\n        Date/Time: {date}"
    );
    if !ctx.author_alt.is_empty() {
        alt_message.push_str(&format!("\n        {}\n", ctx.author_alt));
    }
    if !ctx.comment_alt.is_empty() {
        alt_message.push_str(&format!("        {}\n", ctx.comment_alt));
    }
    alt_message.push_str(&format!("\n\n        Info:\n        {service_output}"));

    let header = style::header_colors(notif_type, service_state);
    let state_colors = style::colors_for(service_state);
    let dynamic_css = style::render_dynamic_css(&header, state_colors.background);

    let html_message = Template::new()
        .set("dynamicCss", dynamic_css)
        .set("type", notif_type)
        .set("attempts", raw.service_attempts.as_deref().unwrap_or_default())
        .set(
            "maxAttempts",
            raw.max_service_attempts.as_deref().unwrap_or_default(),
        )
        .set("serviceDescription", service_displayname)
        .set("status", service_state)
        .set("duration", raw.service_duration.as_deref().unwrap_or_default())
        .set("date", date)
        .set("dynamicHref", href)
        .set("eventType", ctx.event_type)
        .set("author", ctx.author)
        .set("comment", ctx.comment)
        .set("output", service_output)
        .set("graphHtml", graph_html)
        .set_flag("includeAuthor", ctx.include_author)
        .set_flag("includeComment", ctx.include_comment)
        .render(TEMPLATE);

    Notification {
        subject,
        alt_message,
        html_message,
        graph_cid: graph_png.as_ref().map(|_| cid),
        graph_png,
    }
}

fn fetch_graph(args: &Args, host_id: &str, service_id: &str) -> GraphOutcome {
    let raw = &args.raw;
    let (Some(user), Some(token)) = (
        raw.centreon_user.as_deref().filter(|u| !u.is_empty()),
        raw.centreon_token.as_deref().filter(|t| !t.is_empty()),
    ) else {
        return GraphOutcome::NotConfigured;
    };

    let url = format!(
        "{}{}/include/views/graphs/generateGraphs/generateImage.php?akey={}&username={}&chartId={}_{}",
        raw.centreon_url.as_deref().unwrap_or_default(),
        raw.url_path,
        token,
        user,
        host_id,
        service_id,
    );
    graph::fetch(&url, raw.timeout, raw.insecure)
}
