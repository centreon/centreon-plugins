use snafu::prelude::*;
use std::{fs, io, path::PathBuf};

#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display(
        "Threshold: This syntax is a shortcut of '0:{}', so {} must be greater than 0.",
        value,
        value
    ))]
    NegativeSimpleThreshold { value: f64 },

    #[snafu(display("Threshold: The start value {} must be less than the end value {}", start, end))]
    BadThresholdRange { start: f64, end: f64 },

    #[snafu(display("Threshold: Unable to read configuration from {}", path.display()))]
    ReadConfiguration { source: io::Error, path: PathBuf },

    #[snafu(display("Threshold: Threshold not of the form '[@]start:end'"))]
    BadThreshold,

    #[snafu(display("Unable to write result to {}", path.display()))]
    WriteResult { source: io::Error, path: PathBuf },
}

type Result<T, E = Error> = std::result::Result<T, E>;

fn process_data() -> Result<()> {
    let path = "config.toml";
    let configuration = fs::read_to_string(path).context(ReadConfigurationSnafu { path })?;
    let path = unpack_config(&configuration);
    fs::write(&path, b"My complex calculation").context(WriteResultSnafu { path })?;
    Ok(())
}

fn unpack_config(data: &str) -> &str {
    "/some/path/that/does/not/exist"
}
