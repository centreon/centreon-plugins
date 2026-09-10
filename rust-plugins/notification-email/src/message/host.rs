//! Port of `host_message` in `alert.pm`.

use super::{dynamic_href, event_context, Notification};
use crate::cli::Args;
use crate::style;
use crate::template::Template;

const TEMPLATE: &str = include_str!("../templates/host.html");

pub fn render(args: &Args) -> Notification {
    let raw = &args.raw;
    let notif_type = raw.notif_type.as_deref().unwrap_or_default();
    let host_id = raw.host_id.as_deref().unwrap_or_default();
    let host_name = raw.host_name.as_deref().unwrap_or_default();
    let host_alias = raw.host_alias.as_deref().unwrap_or_default();
    let host_state = raw.host_state.as_deref().unwrap_or_default();
    let host_address = raw.host_address.as_deref().unwrap_or_default();
    let host_output = raw.host_output.as_deref().unwrap_or_default();
    let date = raw.date.as_deref().unwrap_or_default();

    let ctx = event_context(notif_type, raw.notif_author.as_deref(), raw.notif_comment.as_deref());

    let href = dynamic_href(
        args,
        host_id,
        &format!("/api/latest/monitoring/resources/hosts/{host_id}"),
        "details",
    );

    let subject = format!("*** {notif_type} : Host: {host_name} {host_state} ***");

    let mut alt_message = format!(
        "\n        ***** Centreon *****\n\n        Notification Type: {notif_type}\n        Hostname: {host_name}\n        Hostalias: {host_alias}\n        State: {host_state}\n        Address: {host_address}\n        Date/Time: {date}"
    );
    if !ctx.author_alt.is_empty() {
        alt_message.push_str(&format!("\n        {}\n", ctx.author_alt));
    }
    if !ctx.comment_alt.is_empty() {
        alt_message.push_str(&format!("        {}\n", ctx.comment_alt));
    }
    alt_message.push_str(&format!("\n\n        Info:\n        {host_output}"));

    let header = style::header_colors(notif_type, host_state);
    let state_colors = style::colors_for(host_state);
    let dynamic_css = style::render_dynamic_css(&header, state_colors.background);

    let html_message = Template::new()
        .set("dynamicCss", dynamic_css)
        .set("type", notif_type)
        .set("attempts", raw.host_attempts.as_deref().unwrap_or_default())
        .set("maxAttempts", raw.max_host_attempts.as_deref().unwrap_or_default())
        .set("hostName", host_name)
        .set("status", host_state)
        .set("duration", raw.host_duration.as_deref().unwrap_or_default())
        .set("hostAlias", host_alias)
        .set("hostAddress", host_address)
        .set("date", date)
        .set("dynamicHref", href)
        .set("eventType", ctx.event_type)
        .set("author", ctx.author)
        .set("comment", ctx.comment)
        .set("output", host_output)
        .set_flag("includeAuthor", ctx.include_author)
        .set_flag("includeComment", ctx.include_comment)
        .render(TEMPLATE);

    Notification {
        subject,
        alt_message,
        html_message,
        graph_png: None,
        graph_cid: None,
    }
}
