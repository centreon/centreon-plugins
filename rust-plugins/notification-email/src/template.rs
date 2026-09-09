//! Minimal stand-in for the subset of `HTML::Template` used by the Perl plugin:
//! `<TMPL_VAR NAME="x">` / `<TMPL_VAR NAME='x'>` substitution and
//! `<TMPL_IF NAME="x">...</TMPL_IF>` block inclusion. No loops, no nesting:
//! the ported templates never use them, so this does not need to support them.

use std::collections::HashMap;

pub struct Template {
    vars: HashMap<&'static str, String>,
    flags: HashMap<&'static str, bool>,
}

impl Template {
    pub fn new() -> Self {
        Template {
            vars: HashMap::new(),
            flags: HashMap::new(),
        }
    }

    pub fn set(mut self, name: &'static str, value: impl Into<String>) -> Self {
        self.vars.insert(name, value.into());
        self
    }

    pub fn set_flag(mut self, name: &'static str, value: bool) -> Self {
        self.flags.insert(name, value);
        self
    }

    /// Renders `source` by resolving `TMPL_IF` blocks first (so a var referenced
    /// only inside a dropped block never needs a value) and then substituting
    /// every `TMPL_VAR`.
    pub fn render(&self, source: &str) -> String {
        let after_if = self.resolve_if_blocks(source);
        self.substitute_vars(&after_if)
    }

    fn resolve_if_blocks(&self, source: &str) -> String {
        let mut out = String::with_capacity(source.len());
        let mut rest = source;
        loop {
            let Some(start) = rest.find("<TMPL_IF NAME=") else {
                out.push_str(rest);
                break;
            };
            out.push_str(&rest[..start]);
            let after_tag = &rest[start..];
            let tag_end = after_tag.find('>').expect("unterminated TMPL_IF tag");
            let name = extract_name(&after_tag[..=tag_end]);
            let body_start = tag_end + 1;
            let close = "</TMPL_IF>";
            let close_pos = after_tag[body_start..]
                .find(close)
                .expect("unterminated TMPL_IF block");
            let body = &after_tag[body_start..body_start + close_pos];
            if *self.flags.get(name.as_str()).unwrap_or(&false) {
                out.push_str(body);
            }
            rest = &after_tag[body_start + close_pos + close.len()..];
        }
        out
    }

    fn substitute_vars(&self, source: &str) -> String {
        let mut out = String::with_capacity(source.len());
        let mut rest = source;
        loop {
            let Some(start) = rest.find("<TMPL_VAR NAME=") else {
                out.push_str(rest);
                break;
            };
            out.push_str(&rest[..start]);
            let after_tag = &rest[start..];
            let tag_end = after_tag.find('>').expect("unterminated TMPL_VAR tag");
            let name = extract_name(&after_tag[..=tag_end]);
            out.push_str(self.vars.get(name.as_str()).map(String::as_str).unwrap_or(""));
            rest = &after_tag[tag_end + 1..];
        }
        out
    }
}

/// Pulls the identifier out of `NAME="x"` or `NAME='x'` from a `<TMPL_VAR ...>`
/// or `<TMPL_IF ...>` opening tag.
fn extract_name(tag: &str) -> String {
    let after = tag.split("NAME=").nth(1).expect("missing NAME attribute");
    let quote = after.chars().next().expect("empty NAME attribute");
    after[1..]
        .split(quote)
        .next()
        .expect("unterminated NAME attribute")
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn substitutes_double_and_single_quoted_vars() {
        let tpl = Template::new().set("hostName", "srv1");
        assert_eq!(
            tpl.render(r#"Host: <TMPL_VAR NAME="hostName">, again <TMPL_VAR NAME='hostName'>"#),
            "Host: srv1, again srv1"
        );
    }

    #[test]
    fn keeps_if_block_when_flag_is_true() {
        let tpl = Template::new()
            .set("author", "jdoe")
            .set_flag("includeAuthor", true);
        assert_eq!(
            tpl.render(r#"<TMPL_IF NAME="includeAuthor">by <TMPL_VAR NAME="author"></TMPL_IF>"#),
            "by jdoe"
        );
    }

    #[test]
    fn drops_if_block_when_flag_is_false() {
        let tpl = Template::new().set_flag("includeAuthor", false);
        assert_eq!(
            tpl.render(r#"before<TMPL_IF NAME="includeAuthor">by <TMPL_VAR NAME="author"></TMPL_IF>after"#),
            "beforeafter"
        );
    }

    #[test]
    fn unset_flag_defaults_to_false() {
        let tpl = Template::new();
        assert_eq!(
            tpl.render(r#"<TMPL_IF NAME="includeComment">x</TMPL_IF>y"#),
            "y"
        );
    }
}
