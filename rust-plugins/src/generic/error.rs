use snafu::prelude::Snafu;
use std::io;

#[derive(Debug, Snafu)]
#[snafu(visibility(pub))]
pub enum Error {
    #[snafu(display(
        "Threshold: This syntax is a shortcut of '0:{}', so {} must be greater than 0.",
        value,
        value
    ))]
    NegativeSimpleThreshold { value: f64 },

    #[snafu(display(
        "Threshold: The start value {} must be less than the end value {}",
        start,
        end
    ))]
    BadThresholdRange { start: f64, end: f64 },

    #[snafu(display("Threshold: The threshold syntax must follow '[@]start:end'"))]
    BadThreshold,

    #[snafu(transparent)]
    Io { source: io::Error },
    #[snafu(transparent)]
    Lexopt { source: lexopt::Error },

    #[snafu(transparent)]
    SerdeJson { source: serde_json::Error },

    #[snafu(transparent)]
    Regex { source: regex::Error },
}

impl From<std::ffi::OsString> for Error {
    fn from(value: std::ffi::OsString) -> Self {
        //let val = value.into_string().unwrap_or_else(|_| "Invalid UTF-8".to_string());
        Error::Lexopt {
            source: lexopt::Error::NonUnicodeValue(value),
        }
    }
}

pub type Result<T, E = Error> = std::result::Result<T, E>;
