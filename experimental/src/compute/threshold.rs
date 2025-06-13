use crate::generic::error::Error;
use std::f64::INFINITY;

pub struct Threshold {
    start: f64,
    end: f64,
    negation: bool,
}

impl Threshold {
    pub fn parse(expr: &str) -> Result<Threshold, Error> {
        // https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT
        let mut start: usize = 0;
        let mut in_number = false;
        let mut current = 0;
        let mut value = [-INFINITY, INFINITY];
        let mut in_range = 0;
        let mut negation = 0;
        for (idx, c) in expr.char_indices() {
            if in_number {
                match c {
                    '0'..='9' => continue,
                    '.' | '-' | '+' | 'e' | 'E' => continue,
                    '@' => {
                        return Err(Error::BadThreshold);
                    }
                    _ => {
                        in_number = false;
                        value[current] = match expr[start..idx].parse() {
                            Ok(x) => x,
                            Err(_) => return Err(Error::BadThreshold),
                        }
                    }
                }
            }
            /* No else here, because we can continue the previous match */
            if !in_number {
                match c {
                    '@' => {
                        negation += 1;
                        if in_range > 0 || current > 0 {
                            return Err(Error::BadThreshold);
                        }
                    }
                    ' ' => continue,
                    '-' => {
                        in_number = true;
                        start = idx;
                    }
                    '0'..='9' => {
                        in_number = true;
                        start = idx;
                    }
                    '~' => {
                        value[0] = -INFINITY;
                    }
                    ':' => {
                        in_range += 1;
                        current = 1;
                    }
                    _ => return Err(Error::BadThreshold),
                }
            }
        }
        if negation > 1 {
            return Err(Error::BadThreshold);
        }
        if in_number {
            value[current] = match expr[start..].parse() {
                Ok(x) => x,
                Err(_) => return Err(Error::BadThreshold),
            }
        }

        /* We have noticed a ':' character, so the threshold is a range */
        if in_range == 1 {
            if value[0] > value[1] {
                return Err(Error::BadThresholdRange {
                    start: value[0],
                    end: value[1],
                });
            }
            return Ok(Threshold {
                start: value[0],
                end: value[1],
                negation: negation > 0,
            });
        } else if in_range > 1 {
            return Err(Error::BadThreshold);
        } else {
            if value[0] <= 0_f64 {
                return Err(Error::NegativeSimpleThreshold { value: value[0] });
            }
            return Ok(Threshold {
                start: 0_f64,
                end: value[0],
                negation: negation > 0,
            });
        }
    }

    pub fn in_alert(&self, value: f64) -> bool {
        if value < self.start || value > self.end {
            if self.negation {
                return false;
            } else {
                return true;
            }
        }
        if self.negation {
            true
        } else {
            false
        }
    }
}

mod test {
    

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
                    "Threshold: The start value 30 must be less than the end value 20"
                );
            }
        }
    }

    #[test]
    fn test_bad_range() {
        let expr = "10:20:30";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The threshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_foobar() {
        let expr = "foobar";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The threshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_12foo() {
        let expr = "12foo";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The threshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_bad_number() {
        let expr = "12e.1.e28";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The threshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_bad_number_and_range() {
        let expr = "12e.1.e28:1.2.3.4";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The threshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_not_allowed_negative() {
        let expr = "-12";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("The threshold '{}' should not be valid", expr);
            }
            Err(err) => {
                assert_eq!(err.to_string(),
                    "Threshold: This syntax is a shortcut of '0:-12', so -12 must be greater than 0.");
            }
        }
    }

    #[test]
    fn test_threshold_negation() {
        let expr = "@2:12";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(t) => {
                assert!(!t.in_alert(1_f64));
                assert!(t.in_alert(2_f64));
                assert!(t.in_alert(3_f64));
                assert!(t.in_alert(12_f64));
                assert!(!t.in_alert(13_f64));
            }
            Err(err) => {
                panic!("We should not have this error here: {}", err);
            }
        }
    }

    #[test]
    fn test_threshold_bad_negation() {
        let expr = "2@:12";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("We should not have a threshold here");
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_bad_negation1() {
        let expr = "2:@12";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("We should not have a threshold here");
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }

    #[test]
    fn test_threshold_bad_negation2() {
        let expr = "@@2:12";
        let threshold = Threshold::parse(expr);
        match threshold {
            Ok(_) => {
                panic!("We should not have a threshold here");
            }
            Err(err) => {
                assert_eq!(
                    err.to_string(),
                    "Threshold: The threshold syntax must follow '[@]start:end'"
                );
            }
        }
    }
}
