//! MIME assembly and SMTP delivery, replacing `Email::MIME` +
//! `Email::Sender::Transport::SMTP` from the `run` sub in `alert.pm`.

use crate::cli::Args;
use crate::message::Notification;
use lettre::message::header::ContentType;
use lettre::message::{Attachment, Mailbox, Message, MultiPart, SinglePart};
use lettre::transport::smtp::authentication::Credentials;
use lettre::{SmtpTransport, Transport};

pub fn send(args: &Args, notif: &Notification) -> Result<(), String> {
    let raw = &args.raw;

    let from: Mailbox = raw
        .from_address
        .as_deref()
        .unwrap_or_default()
        .parse()
        .map_err(|e| format!("invalid --from-address: {e}"))?;
    let to: Mailbox = raw
        .to_address
        .as_deref()
        .unwrap_or_default()
        .parse()
        .map_err(|e| format!("invalid --to-address: {e}"))?;

    let alternative = MultiPart::alternative()
        .singlepart(SinglePart::plain(notif.alt_message.clone()))
        .singlepart(SinglePart::html(notif.html_message.clone()));

    let body = match (&notif.graph_png, &notif.graph_cid) {
        (Some(png), Some(cid)) => MultiPart::mixed().multipart(alternative).singlepart(
            Attachment::new_inline(cid.clone()).body(png.clone(), ContentType::parse("image/png").unwrap()),
        ),
        _ => alternative,
    };

    let email = Message::builder()
        .from(from)
        .to(to)
        .subject(notif.subject.clone())
        .multipart(body)
        .map_err(|e| format!("failed to build email: {e}"))?;

    let mailer = build_transport(raw)?;
    mailer.send(&email).map_err(|e| format!("SMTP Error: {e}"))?;
    Ok(())
}

fn build_transport(raw: &crate::cli::Cli) -> Result<SmtpTransport, String> {
    let host = raw.smtp_address.as_deref().unwrap_or_default();
    let port: u16 = raw
        .smtp_port
        .parse()
        .map_err(|_| format!("invalid --smtp-port: {}", raw.smtp_port))?;

    let mut builder = if raw.smtp_nossl {
        SmtpTransport::builder_dangerous(host).port(port)
    } else {
        SmtpTransport::starttls_relay(host)
            .map_err(|e| format!("invalid --smtp-address: {e}"))?
            .port(port)
    };

    if let Some(user) = raw.smtp_user.as_deref().filter(|u| !u.is_empty()) {
        let password = raw.smtp_password.clone().unwrap_or_default();
        builder = builder.credentials(Credentials::new(user.to_string(), password));
    }

    Ok(builder.build())
}
