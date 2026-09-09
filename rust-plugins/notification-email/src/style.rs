//! State-to-color mapping and dynamic CSS rendering, ported from
//! `notification::email::mode::alert`'s `%color` table and
//! `notification::email::templates::style`.

use crate::template::Template;

pub const STYLE_TEMPLATE: &str = include_str!("templates/style.css");

pub struct Colors {
    pub background: &'static str,
    pub text: &'static str,
}

/// Looks up the background/text color pair for a state or event-type keyword
/// (e.g. `"up"`, `"critical"`, `"acknowledgement"`), case-insensitively.
///
/// Returns white-on-black if the keyword is unrecognized, matching the
/// `$background_color = 'white'; $text_color = 'black';` fallback in the
/// Perl source (which is otherwise always overwritten before use there).
pub fn colors_for(keyword: &str) -> Colors {
    match keyword.to_lowercase().as_str() {
        "up" | "ok" => Colors { background: "#88B922", text: "#FFFFFF" },
        "down" | "critical" => Colors { background: "#FF4A4A", text: "#FFFFFF" },
        "warning" => Colors { background: "#FD9B27", text: "#FFFFFF" },
        "unknown" | "unreachable" => Colors { background: "#E0E0E0", text: "#666666" },
        "acknowledgement" => Colors { background: "#F5F1E9", text: "#666666" },
        "downtimestart" | "downtimeend" | "downtimecanceled" => {
            Colors { background: "#F0E9F8", text: "#666666" }
        }
        _ => Colors { background: "white", text: "black" },
    }
}

/// Picks which keyword drives the header color: the entity state for
/// PROBLEM/RECOVERY notifications, the notification type otherwise (matching
/// each `*_message` sub's `if ($type =~ /^problem|recovery$/i) ... else ...`).
pub fn header_colors(notif_type: &str, state: &str) -> Colors {
    if notif_type.eq_ignore_ascii_case("problem") || notif_type.eq_ignore_ascii_case("recovery") {
        colors_for(state)
    } else {
        colors_for(notif_type)
    }
}

pub fn render_dynamic_css(header: &Colors, state_color: &str) -> String {
    Template::new()
        .set("backgroundColor", header.background)
        .set("textColor", header.text)
        .set("stateColor", state_color)
        .render(STYLE_TEMPLATE)
}
