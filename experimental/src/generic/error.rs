use snafu::prelude::Snafu;
use std::path::PathBuf;

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

    #[snafu(display("Json: Failed to parse JSON: {}", message))]
    JsonParse { message: String },

    #[snafu(display("Json: Unable to read the JSON file '{}'", path.display()))]
    JsonRead {
        source: std::io::Error,
        path: PathBuf,
    },
}

pub type Result<T, E = Error> = std::result::Result<T, E>;
