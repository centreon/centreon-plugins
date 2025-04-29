pub mod ast;
pub mod lexer;

use self::ast::ExprResult;
use self::lexer::{LexicalError, Tok};
use lalrpop_util::{lalrpop_mod, ParseError};
use log::{trace, debug};
use regex::Regex;
use serde::Deserialize;
use snmp::SnmpResult;

lalrpop_mod!(grammar);

#[derive(Deserialize, Debug)]
pub struct Metric {
    pub name: String,
    pub prefix: Option<String>,
    pub value: String,
    uom: Option<String>,
    pub min_expr: Option<String>,
    pub min: Option<f64>,
    pub max_expr: Option<String>,
    pub max: Option<f64>,
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
        let mut result: ExprResult = ExprResult::StrVector(vec![]);
        loop {
            let found = re.find(suffix);
            if let Some(m) = found {
                let start = m.start();
                let end = m.end();
                debug!(
                    "Identifier '{}' found in expr '{}'",
                    &expr[start + 1..end - 1],
                    expr
                );
                let prefix = &expr[0..start];
                suffix = &expr[end..];
                let mut result = vec![];
                for snmp_result in self.collect {
                    if let Some(v) = snmp_result.items.get(&expr[start + 1..end - 1]) {
                        result = join_str_expr(prefix, v);
                        break;
                    }
                }
                trace!("Result string {:?}", result);
            } else {
                break;
            }
        }
        Ok(result)
    }
}

fn join_str_expr(prefix: &str, v: &ExprResult) -> Vec<String> {
    match v {
        ExprResult::StrVector(v) => {
            let mut result = vec![];
            for item in v {
                result.push(format!("{}{}", prefix, item));
            }
            result
        }
        _ => panic!("Expected a string vector"),
    }
}

mod Test {
    use super::*;
    use log::info;
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
            ExprResult::Scalar(n) => assert!(n == 123_f64),
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
            ExprResult::Scalar(n) => assert!(n == 3_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 + 2 - 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == 0_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 - 2 + 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == 2_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 - (2 + 3)");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == -4_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 - (2 + (3 - (4 + (5 - (6 + 7)))))");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == -8_f64),
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
            ExprResult::Scalar(n) => assert!(n == 6_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("1 + 2 * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == 7_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("(1 + 2) * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == 9_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("2 * 3 * 4");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == 24_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("2 * 3 / 2");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        let res = res.unwrap().eval(&snmp_result);
        match res {
            ExprResult::Scalar(n) => assert!(n == 3_f64),
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
            ExprResult::Scalar(n) => assert!(n == 4_f64),
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
            ExprResult::Scalar(n) => assert!(n == 2_f64),
            _ => panic!("Expected a scalar value"),
        }

        let lexer = lexer::Lexer::new("abc + 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_err());
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
            ExprResult::Scalar(n) => assert!(n == 96.04125652657707_f64),
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
            ExprResult::Scalar(n) => assert!(n == 2_f64),
            _ => panic!("Expected a scalar value"),
        }
    }

    #[test]
    fn identifier_str() {
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
                assert_eq!(v.len(), 4);
                assert_eq!(v[0], "free-onefoo");
                assert_eq!(v[1], "free-twofoo");
                assert_eq!(v[2], "total-onebar");
                assert_eq!(v[3], "total-twobar");
            }
            _ => panic!("Expected a string vector"),
        }
    }
}
