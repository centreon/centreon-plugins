use generic::error::Error;
use log::{debug, error, info, trace, warn};
use std::f64::INFINITY;

pub struct Threshold {
    start: f64,
    end: f64,
}

impl Threshold {
    pub fn parse(expr: &str) -> Result<Threshold, Error> {
        // https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT
        let mut start: usize = 0;
        let mut in_number = false;
        let mut current = 0;
        let mut value = [-INFINITY, INFINITY];
        let mut in_range = false;
        for (idx, c) in expr.char_indices() {
            if in_number {
                match c {
                    '0'..='9' => continue,
                    '.' | '-' | '+' | 'e' | 'E' => continue,
                    _ => {
                        in_number = false;
                        value[current] = match expr[start..idx].parse() {
                            Ok(x) => x,
                            Err(err) => {
                                error!("parse error: {}", err);
                                std::process::exit(3);
                            }
                        }
                    }
                }
            }
            /* No else here, because we can continue the previous match */
            if !in_number {
                match c {
                    ' ' => continue,
                    '0'..='9' => {
                        in_number = true;
                        start = idx;
                    }
                    '~' => {
                        value[0] = -INFINITY;
                    }
                    ':' => {
                        in_range = true;
                        current = 1;
                    }
                    _ => break,
                }
            }
        }
        if in_number {
            value[current] = match expr[start..].parse() {
                Ok(x) => x,
                Err(err) => {
                    error!("parse error: {}", err);
                    std::process::exit(3);
                }
            }
        }

        /* We have noticed a ':' character, so the threshold is a range */
        if in_range {
            if value[0] > value[1] {
                return Err(Error::BadThresholdRange {
                    start: value[0],
                    end: value[1],
                });
            }
            return Ok(Threshold {
                start: value[0],
                end: value[1],
            });
        } else {
            if value[0] <= 0_f64 {
                return Err(Error::NegativeSimpleThreshold { value: value[0] });
            }
            return Ok(Threshold {
                start: 0_f64,
                end: value[0],
            });
        }
    }

    fn in_alert(&self, value: f64) -> bool {
        if value < self.start || value > self.end {
            return true;
        }
        false
    }
}

mod Test {
    use super::*;

    #[test]
    fn test_parse_value() {
        let expr = "1.2";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(threshold) => {
                assert_eq!(threshold.start, 0_f64);
                assert_eq!(threshold.end, 1.2_f64);
                assert!(threshold.in_alert(2_f64));
                assert!(threshold.in_alert(-1_f64));
            }
            Err(err) => {
                panic!("We should not have this error here: {}", err);
            }
        }
    }

    #[test]
    fn test_parse_val_colon() {
        let expr = "10:";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(threshold) => {
                assert_eq!(threshold.start, 10_f64);
                assert_eq!(threshold.end, INFINITY);
                assert!(!threshold.in_alert(10_f64));
                assert!(!threshold.in_alert(11_f64));
                assert!(threshold.in_alert(9_f64));
            }
            Err(err) => {
                panic!("We should not have this error here: {}", err);
            }
        }
    }

    #[test]
    fn test_parse_tilda_val() {
        let expr = "~:10";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(threshold) => {
                assert_eq!(threshold.start, -INFINITY);
                assert_eq!(threshold.end, 10_f64);
                assert!(!threshold.in_alert(10_f64));
                assert!(threshold.in_alert(11_f64));
                assert!(!threshold.in_alert(9_f64));
            }
            Err(err) => {
                panic!("We should not have this error here: {}", err);
            }
        }
    }

    #[test]
    fn test_parse_val_val() {
        let expr = "10:20";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(threshold) => {
                assert_eq!(threshold.start, 10_f64);
                assert_eq!(threshold.end, 20_f64);
                assert!(!threshold.in_alert(10_f64));
                assert!(!threshold.in_alert(11_f64));
                assert!(threshold.in_alert(9_f64));
                assert!(threshold.in_alert(21_f64));
            }
            Err(err) => {
                panic!("We should not have this error here: {}", err);
            }
        }
    }

    #[test]
    fn test_parse_bad_val_val() {
        let expr = "30:20";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The thrshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "The start value 30 must be less than the end value 20"
                );
            }
        }
    }
}
