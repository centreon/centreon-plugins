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

    #[snafu(display("Unknown argument: {arg}\nUse --help to display available options"))]
    UnknownArgument { arg: String },

    #[snafu(display(
        "Invalid status '{}': expected one of OK, WARNING, CRITICAL, UNKNOWN",
        value
    ))]
    InvalidStatus { value: String },

    #[snafu(display("{message}"))]
    InvalidJSON { message: String },

    #[snafu(display("Could not parse oid {}", oid))]
    InvalidOidParser { oid: String },

    #[snafu(display("Could not encode Snmp PDU received from server"))]
    InvalidSnmpPduEncode {},

    #[snafu(display("Could not decode Snmp PDU received from server : {}", err))]
    InvalidSnmpPduDecode { err: String },

    #[snafu(display("Could not decode a value in the Snmp response : {}", detail))]
    InvalidSnmpValue { detail: String },

    #[snafu(display("Expected Type : {} for snmp oid", detail))]
    InvalidSnmpType { detail: String },

    #[snafu(display(
        "Empty response from the server. Does the community have sufficient permissions ?"
    ))]
    EmptyResponse {},
    #[snafu(display(
        "Could not connect to {} is the hostname and the snmp community correct ? {}",
        url,
        os
    ))]
    FailedToConnectToHost { url: String, os: String },

    #[snafu(display(
        "SNMP agent returned an error: {} (status {}, index {})",
        name,
        status,
        index
    ))]
    SnmpAgentError {
        name: &'static str,
        status: u32,
        index: u32,
    },

    #[snafu(display("SNMP agent is misbehaving: OID {} is not increasing during walk", oid))]
    OidNotIncreasing { oid: String },

    #[snafu(display(
        "SNMP walk aborted: the agent returned more than {} values for a single subtree",
        max
    ))]
    WalkTooLarge { max: usize },

    #[snafu(display("SNMP collection exceeded the global timeout of {}s", seconds))]
    CollectTimeout { seconds: u64 },

    #[snafu(display(
        "Could not persist the state file {} ({}): rates would be computed against a stale reference",
        path,
        reason
    ))]
    StatefileWrite { path: String, reason: String },

    #[snafu(display(
        "No valid SNMP response from {} after {} attempts (timeout {}s per attempt)",
        url,
        attempts,
        timeout
    ))]
    RequestTimeout {
        url: String,
        attempts: u32,
        timeout: u64,
    },

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
