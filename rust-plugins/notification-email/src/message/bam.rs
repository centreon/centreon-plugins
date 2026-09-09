//! Port of `bam_message` in `alert.pm`.

use super::{event_context, Notification};
use crate::cli::Args;
use crate::style;
use crate::template::Template;

const TEMPLATE: &str = include_str!("../templates/bam.html");

pub fn render(args: &Args) -> Notification {
    let raw = &args.raw;
    let notif_type = raw.notif_type.as_deref().unwrap_or_default();
    let service_description = raw.service_description.as_deref().unwrap_or_default();
    let service_displayname = raw.service_displayname.as_deref().unwrap_or_default();
    let service_state = raw.service_state.as_deref().unwrap_or_default();
    let service_output = raw.service_output.as_deref().unwrap_or_default();
    let date = raw.date.as_deref().unwrap_or_default();

    let ctx = event_context(notif_type, raw.notif_author.as_deref(), raw.notif_comment.as_deref());

    let ba_id = extract_ba_id(service_description);
    let href = format!(
        "{}{}/main.php?p=20701&o=d&ba_id={}",
        raw.centreon_url.as_deref().unwrap_or_default(),
        raw.url_path,
        ba_id
    );

    let subject = format!("*** {notif_type} BAM: {service_displayname} {service_state} ***");

    let mut alt_message = format!(
        "\n        ***** Centreon BAM *****\n\n        Notification Type: {notif_type}\n        Service: {service_displayname}\n        State: {service_state}\n        Date/Time: {date}"
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
        .set("serviceDescription", service_displayname)
        .set("status", service_state)
        .set("duration", raw.service_duration.as_deref().unwrap_or_default())
        .set("date", date)
        .set("dynamicHref", href)
        .set("eventType", ctx.event_type)
        .set("author", ctx.author)
        .set("comment", ctx.comment)
        .set("output", service_output)
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

/// Ports `$service_description =~ /ba_(\d+)/; my $ba_id = $1;`: the first run
/// of digits right after a `ba_` substring, or empty if there is none (an
/// unmatched `$1` is undef in Perl, which stringifies to "" here too).
fn extract_ba_id(service_description: &str) -> String {
    let Some(pos) = service_description.find("ba_") else {
        return String::new();
    };
    service_description[pos + 3..]
        .chars()
        .take_while(|c| c.is_ascii_digit())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::extract_ba_id;

    #[test]
    fn extracts_digits_after_ba_prefix() {
        assert_eq!(extract_ba_id("_Module_BAM_1_ba_42"), "42");
    }

    #[test]
    fn empty_when_no_ba_prefix() {
        assert_eq!(extract_ba_id("no-match-here"), "");
    }
}
