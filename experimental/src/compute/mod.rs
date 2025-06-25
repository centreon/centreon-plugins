pub mod ast;
pub mod lexer;
pub mod threshold;

use self::ast::ExprResult;
use self::lexer::{LexicalError, Tok};
use crate::snmp::SnmpResult;
use lalrpop_util::{ParseError, lalrpop_mod};
use log::debug;
use regex::Regex;
use serde::Deserialize;

lalrpop_mod!(grammar);

#[derive(Deserialize, Debug)]
pub struct Metric {
    pub name: String,
    pub prefix: Option<String>,
    pub value: String,
    #[serde(default = "empty_string")]
    pub uom: String,
    pub min_expr: Option<String>,
    pub min: Option<f64>,
    pub max_expr: Option<String>,
    pub max: Option<f64>,
    #[serde(rename = "threshold-suffix")]
    pub threshold_suffix: Option<String>,
    pub warning: Option<String>,
    pub critical: Option<String>,
}

fn empty_string() -> String {
    "".to_string()
}

#[derive(Deserialize, Debug)]
pub struct Compute {
    pub metrics: Vec<Metric>,
    pub aggregations: Option<Vec<Metric>>,
}

pub struct Parser<'a> {
    collect: &'a Vec<SnmpResult>,
    parser: grammar::ExprParser,
}

impl<'a> Parser<'a> {
    pub fn new(collect: &'a Vec<SnmpResult>) -> Parser<'a> {
        Parser {
            collect,
            parser: grammar::ExprParser::new(),
        }
    }

    pub fn eval(
        &self,
        expr: &'a str,
    ) -> Result<ExprResult, ParseError<usize, Tok<'a>, LexicalError>> {
        debug!("Parsing expression: {}", expr);
        let lexer = lexer::Lexer::new(expr);
        let res = self.parser.parse(lexer);
        match res {
            Ok(res) => {
                let res = res.eval(self.collect);
                Ok(res)
            }
            Err(e) => Err(e),
        }
    }

    pub fn eval_str(
        &self,
        expr: &'a str,
    ) -> Result<ExprResult, ParseError<usize, Tok<'a>, LexicalError>> {
        let re = Regex::new(r"\{[a-zA-Z_][a-zA-Z0-9_.]*\}").unwrap();
        let mut suffix = expr;
        let mut result: ExprResult = ExprResult::Empty;
        loop {
            let found = re.find(suffix);
            if let Some(m) = found {
                let start = m.start();
                let end = m.end();
                if start > 0 {
                    result.join(&ExprResult::Str(suffix[0..start].to_string()));
                }
                for snmp_result in self.collect {
                    if let Some(v) = snmp_result.items.get(&suffix[start + 1..end - 1]) {
                        result.join(v);
                        break;
                    }
                }
                debug!(
                    "Evaluation as string of expression '{}' returns {:?}",
                    suffix, result
                );
                suffix = &suffix[end..];
            } else {
                result.join(&ExprResult::Str(suffix.to_string()));
                break;
            }
        }
        Ok(result)
    }
}

mod test {
    use crate::compute::{Parser, ast::ExprResult, grammar, lexer};
    use crate::snmp::SnmpResult;
    use log::{debug, info};
    use std::collections::HashMap;

    fn init() {
        let _ = env_logger::builder().is_test(true).try_init();
    }

    #[test]
    fn term() {
        init();
        info!("test term");
        let lexer = lexer::Lexer::new("123");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let snmp_result = vec![];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 123_f64),
            _ => panic!("Expected a scalar value"),
        }
        let lexer = lexer::Lexer::new("123");
        assert!(grammar::ExprParser::new().parse(lexer).is_ok());
        let lexer = lexer::Lexer::new("(((123))");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
    }

    #[test]
    fn sum() {
        init();
        let lexer = lexer::Lexer::new("1 + 2");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let snmp_result = vec![];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 3_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 + 2 - 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 0_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 - 2 + 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 2_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 - (2 + 3)");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == -4_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 - (2 + (3 - (4 + (5 - (6 + 7)))))");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == -8_f64),
            _ => panic!("Expected a scalar value"),
        }
    }

    #[test]
    fn product() {
        init();
        let lexer = lexer::Lexer::new("2 * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let snmp_result = vec![];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 6_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 + 2 * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 7_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("(1 + 2) * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 9_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("2 * 3 * 4");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 24_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("2 * 3 / 2");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 3_f64),
            _ => panic!("Expected a scalar value"),
        }

        // We have an issue with 2/0, I know it but we'll fix it later.
    }

    #[test]
    fn sum_product() {
        init();
        let lexer = lexer::Lexer::new("1 + (3 + 2 * 3) / 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let snmp_result = vec![];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 4_f64),
            _ => panic!("Expected a scalar value"),
        }
    }

    #[test]
    fn identifier() {
        init();
        let lexer = lexer::Lexer::new("{abc} + 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        println!("{:?}", res);
        let items = HashMap::from([("abc".to_string(), ExprResult::Vector(vec![1_f64]))]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 2_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("abc + 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
    }

    #[test]
    fn vec_sum() {
        init();
        let lexer = lexer::Lexer::new("{abc} + {def}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        println!("{:?}", res);
        let items = HashMap::from([
            ("abc".to_string(), ExprResult::Vector(vec![1_f64, 2_f64])),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 4_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![4_f64, 6_f64]),
            _ => panic!("Expected a vector value"),
        }

        let lexer = lexer::Lexer::new("abc + 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
    }

    #[test]
    fn vec_sum_diff_len() {
        let lexer = lexer::Lexer::new("{abc} + {def} + {ghi}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([
            (
                "abc".to_string(),
                ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
            ),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 4_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64, 8_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![9_f64, 12_f64, 12_f64, 8_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_scalar_sum() {
        let lexer = lexer::Lexer::new("{abc} + 5");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![6_f64, 7_f64, 10_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn scalar_vec_sum() {
        let lexer = lexer::Lexer::new("18 + {abc}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![19_f64, 20_f64, 23_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_sub() {
        init();
        let lexer = lexer::Lexer::new("{abc} - {def}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        println!("{:?}", res);
        let items = HashMap::from([
            ("abc".to_string(), ExprResult::Vector(vec![1_f64, 3_f64])),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 4_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![-2_f64, -1_f64]),
            _ => panic!("Expected a vector value"),
        }

        let lexer = lexer::Lexer::new("abc + 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
    }

    #[test]
    fn vec_sub_diff_len() {
        let lexer = lexer::Lexer::new("{abc} - {def} - {ghi}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([
            (
                "abc".to_string(),
                ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
            ),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 4_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64, 8_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![-7_f64, -8_f64, -2_f64, -8_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn scalar_vec_sub() {
        let lexer = lexer::Lexer::new("18 - {abc}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![17_f64, 16_f64, 13_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_scalar_sub() {
        let lexer = lexer::Lexer::new("{abc} - 19.2");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![-18.2_f64, -17.2_f64, -14.2_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_mul() {
        init();
        let lexer = lexer::Lexer::new("{abc} * {def}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        println!("{:?}", res);
        let items = HashMap::from([
            ("abc".to_string(), ExprResult::Vector(vec![1_f64, 3_f64])),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 4_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![3_f64, 12_f64]),
            _ => panic!("Expected a vector value"),
        }

        let lexer = lexer::Lexer::new("abc * 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
    }

    #[test]
    fn vec_mul_diff_len() {
        let lexer = lexer::Lexer::new("{abc} * {def} * {ghi}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([
            (
                "abc".to_string(),
                ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
            ),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 4_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64, 8_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![15_f64, 48_f64, 35_f64, 8_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn scalar_vec_mul() {
        let lexer = lexer::Lexer::new("18 * {abc}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![18_f64, 36_f64, 90_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_scalar_mul() {
        let lexer = lexer::Lexer::new("{abc} * 4");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![4_f64, 8_f64, 20_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_div() {
        init();
        let lexer = lexer::Lexer::new("{abc} / {def}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        println!("{:?}", res);
        let items = HashMap::from([
            ("abc".to_string(), ExprResult::Vector(vec![3_f64, 12_f64])),
            ("def".to_string(), ExprResult::Vector(vec![1_f64, 3_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![5_f64, 6_f64, 7_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![3_f64, 4_f64]),
            _ => panic!("Expected a vector value"),
        }

        let lexer = lexer::Lexer::new("abc * 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
    }

    #[test]
    fn vec_div_diff_len() {
        let lexer = lexer::Lexer::new("{abc} / {def} / {ghi}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([
            (
                "abc".to_string(),
                ExprResult::Vector(vec![12_f64, 22_f64, 15_f64]),
            ),
            ("def".to_string(), ExprResult::Vector(vec![3_f64, 11_f64])),
            (
                "ghi".to_string(),
                ExprResult::Vector(vec![2_f64, 2_f64, 3_f64, 8_f64]),
            ),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![2_f64, 1_f64, 5_f64, 0.125_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn scalar_vec_div() {
        let lexer = lexer::Lexer::new("18 / {abc}");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![18_f64, 9_f64, 3.6_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn vec_scalar_div() {
        let lexer = lexer::Lexer::new("{abc} / 4");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        debug!("{:?}", res);
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 5_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        debug!("{:?}", res);
        match res {
            ExprResult::Vector(v) => assert!(v == vec![0.25_f64, 0.5_f64, 1.25_f64]),
            _ => panic!("Expected a vector value"),
        }
    }

    #[test]
    fn two_identifiers() {
        init();
        let lexer = lexer::Lexer::new("100 * (1 - {free}/{total})");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let items = HashMap::from([
            ("free".to_string(), ExprResult::Vector(vec![29600_f64])),
            ("total".to_string(), ExprResult::Vector(vec![747712_f64])),
        ]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 96.04125652657707_f64),
            _ => panic!("Expected a scalar value"),
        }
    }

    #[test]
    fn function() {
        init();
        let lexer = lexer::Lexer::new("Average({abc})");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let items = HashMap::from([(
            "abc".to_string(),
            ExprResult::Vector(vec![1_f64, 2_f64, 3_f64]),
        )]);
        let snmp_result = vec![SnmpResult::new(items)];
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Number(n) => assert!(n == 2_f64),
            _ => panic!("Expected a scalar value"),
        }
    }

    #[test]
    fn join_str_str_identifier() {
        init();
        let items = HashMap::from([
            (
                "free".to_string(),
                ExprResult::StrVector(vec!["free-one".to_string(), "free-two".to_string()]),
            ),
            (
                "total".to_string(),
                ExprResult::StrVector(vec!["total-one".to_string(), "total-two".to_string()]),
            ),
        ]);
        let collect = vec![SnmpResult::new(items)];
        let parser = Parser::new(&collect);
        let res = parser.eval_str("{free}foo{total}bar");
        assert!(res.is_ok());
        let res = res.unwrap();
        match res {
            ExprResult::StrVector(v) => {
                assert_eq!(v.len(), 2);
                assert_eq!(v[0], "free-onefoototal-onebar");
                assert_eq!(v[1], "free-twofoototal-twobar");
            }
            _ => panic!("Expected a string vector"),
        }
    }

    #[test]
    fn join_str_identifier_str() {
        init();
        let items = HashMap::from([
            (
                "free".to_string(),
                ExprResult::StrVector(vec!["free-one".to_string(), "free-two".to_string()]),
            ),
            (
                "total".to_string(),
                ExprResult::StrVector(vec!["total-one".to_string(), "total-two".to_string()]),
            ),
        ]);
        let collect = vec![SnmpResult::new(items)];
        let parser = Parser::new(&collect);
        let res = parser.eval_str("test{free}{total}foo{free}");
        assert!(res.is_ok());
        let res = res.unwrap();
        match res {
            ExprResult::StrVector(v) => {
                assert_eq!(v.len(), 2);
                assert_eq!(v[0], "testfree-onetotal-onefoofree-one");
                assert_eq!(v[1], "testfree-twototal-twofoofree-two");
            }
            _ => panic!("Expected a string vector"),
        }
    }

    #[test]
    fn str_to_value_in_str() {
        init();
        let items = HashMap::from([
            ("free".to_string(), ExprResult::Vector(vec![1.1, 2.2, 3.3])),
            ("total".to_string(), ExprResult::Vector(vec![2.1, 3.2, 4.3])),
        ]);
        let collect = vec![SnmpResult::new(items)];
        let parser = Parser::new(&collect);
        let res = parser.eval_str("test{free}{total}foo{free}");
        assert!(res.is_ok());
        let res = res.unwrap();
        match res {
            ExprResult::StrVector(v) => {
                assert_eq!(v.len(), 3);
                assert_eq!(v[0], "test1.12.1foo1.1");
                assert_eq!(v[1], "test2.23.2foo2.2");
            }
            _ => panic!("Expected a string vector"),
        }
    }

    #[test]
    fn join_str_str_str() {
        let mut a = ExprResult::Str("test".to_string());
        let b = ExprResult::Str("foobar".to_string());
        a.join(&b);
        match a {
            ExprResult::Str(s) => assert_eq!(s, "testfoobar".to_string()),
            _ => panic!("Expected a string"),
        }
    }
}
