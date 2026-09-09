//! Port of `service_message` in `alert.pm`.

use super::{dynamic_href, event_context, Notification};
use crate::cli::Args;
use crate::graph::{self, GraphOutcome};
use crate::sparkline::{self, SparklineOutcome};
use crate::style;
use crate::template::Template;

const TEMPLATE: &str = include_str!("../templates/service.html");

pub fn render(args: &Args) -> Notification {
    let raw = &args.raw;
    let notif_type = raw.notif_type.as_deref().unwrap_or_default();
    let host_id = raw.host_id.as_deref().unwrap_or_default();
    let service_id = raw.service_id.as_deref().unwrap_or_default();
    let host_name = raw.host_name.as_deref().unwrap_or_default();
    let host_alias = raw.host_alias.as_deref().unwrap_or_default();
    let host_address = raw.host_address.as_deref().unwrap_or_default();
    let service_description = raw.service_description.as_deref().unwrap_or_default();
    let service_state = raw.service_state.as_deref().unwrap_or_default();
    let service_output = raw.service_output.as_deref().unwrap_or_default();
    let service_longoutput = raw.service_longoutput.as_deref().unwrap_or_default();
    let date = raw.date.as_deref().unwrap_or_default();

    let ctx = event_context(notif_type, raw.notif_author.as_deref(), raw.notif_comment.as_deref());

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
        let outcome = fetch_graph(args, host_name, service_description);
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

    let subject =
        format!("*** {notif_type} : {service_description} {service_state} on {host_name} ***");

    let mut alt_message = format!(
        "\n    ***** Centreon *****\n\n    Notification Type: {notif_type}\n    Service: {service_description}\n    Hostname: {host_name}\n    Hostalias: {host_alias}\n    State: {service_state}\n    Address: {host_address}\n    Date/Time: {date}"
    );
    if !ctx.author_alt.is_empty() {
        alt_message.push_str(&format!("\n    {}\n", ctx.author_alt));
    }
    if !ctx.comment_alt.is_empty() {
        alt_message.push_str(&format!("    {}\n", ctx.comment_alt));
    }
    alt_message.push_str(&format!(
        "\n\n    Info:\n    {service_output}\n    {service_longoutput}"
    ));

    let long_output_html = service_longoutput.replace('\n', "<br />");
    let output_html = format!("{service_output}<br />{long_output_html}");

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
        .set("hostName", host_name)
        .set("serviceDescription", service_description)
        .set("status", service_state)
        .set("duration", raw.service_duration.as_deref().unwrap_or_default())
        .set("hostAlias", host_alias)
        .set("hostAddress", host_address)
        .set("date", date)
        .set("dynamicHref", href)
        .set("eventType", ctx.event_type)
        .set("author", ctx.author)
        .set("comment", ctx.comment)
        .set("output", output_html)
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

fn fetch_graph(args: &Args, host_name: &str, service_description: &str) -> GraphOutcome {
    let raw = &args.raw;
    let (Some(user), Some(token)) = (
        raw.centreon_user.as_deref().filter(|u| !u.is_empty()),
        raw.centreon_token.as_deref().filter(|t| !t.is_empty()),
    ) else {
        return GraphOutcome::NotConfigured;
    };

    let url = format!(
        "{}{}/include/views/graphs/generateGraphs/generateImage.php?akey={}&username={}&hostname={}&service={}",
        raw.centreon_url.as_deref().unwrap_or_default(),
        raw.url_path,
        token,
        user,
        host_name,
        service_description,
    );
    graph::fetch(&url, raw.timeout, raw.insecure)
}
