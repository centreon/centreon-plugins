use std::f64::INFINITY;

use log::{debug, error, info, trace, warn};

pub struct Threshold {
    start: f64,
    end: f64,
}

impl Threshold {
    pub fn parse(expr: &str) -> Threshold {
        // https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT
        let mut start: usize = 0;
        let mut in_number = false;
        let mut start_value = -INFINITY;
        let mut end_value = INFINITY;
        let mut in_range = false;
        for (idx, c) in expr.char_indices() {
            if in_number {
                match c {
                    '0'..='9' => continue,
                    '.' | '-' | '+' | 'e' | 'E' => continue,
                    _ => {
                        in_number = false;
                        start_value = match expr[start..idx].parse() {
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
                    ':' => {
                        in_range = true;
                    }
                    _ => break,
                }
            }
        }
        if in_number {
            start_value = match expr[start..].parse() {
                Ok(x) => x,
                Err(err) => {
                    error!("parse error: {}", err);
                    std::process::exit(3);
                }
            }
        }

        /* We have noticed a ':' character, so the threshold is a range */
        if in_range {
            return Threshold {
                start: start_value,
                end: INFINITY,
            };
        } else {
            return Threshold {
                start: 0_f64,
                end: start_value,
            };
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
        assert_eq!(threshold.start, 0_f64);
        assert_eq!(threshold.end, 1.2_f64);
        assert!(threshold.in_alert(2_f64));
        assert!(threshold.in_alert(-1_f64));
    }

    #[test]
    fn test_parse_val_colon() {
        let expr = "10:";
        let threshold = Threshold::parse(expr);
        assert_eq!(threshold.start, 10_f64);
        assert_eq!(threshold.end, INFINITY);
        assert!(!threshold.in_alert(10_f64));
        assert!(!threshold.in_alert(11_f64));
        assert!(threshold.in_alert(9_f64));
    }
}
