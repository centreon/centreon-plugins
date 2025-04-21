pub mod ast;
pub mod lexer;

use self::ast::ExprResult;
use self::lexer::{LexicalError, Tok};
use lalrpop_util::{lalrpop_mod, ParseError};
use serde::Deserialize;
use snmp::SnmpResult;

lalrpop_mod!(grammar);

#[derive(Deserialize, Debug)]
pub struct Metric {
    pub name: String,
    pub prefix: Option<String>,
    pub value: String,
    uom: Option<String>,
    min: Option<f64>,
    max: Option<f64>,
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
}

mod Test {
    use super::*;
    use snmp::SnmpItem;
    use std::collections::HashMap;

    #[test]
    fn term() {
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
        let lexer = lexer::Lexer::new("{abc} + 1");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        println!("{:?}", res);
        let items = HashMap::from([("abc".to_string(), SnmpItem::Nbr(vec![1_f64]))]);
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
    fn function() {
        //        let res = grammar::ExprParser::new().parse("Average(1, 2, 3)");
        //        assert!(res.is_ok());
        //        assert!(res.unwrap() == 2_f32);
        //
        //        let res = grammar::ExprParser::new().parse("Average(1 + 2 * 2, 3, 4)");
        //        assert!(res.is_ok());
        //        assert!(res.unwrap() == 4_f32);
    }
}
