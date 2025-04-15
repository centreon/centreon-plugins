pub mod lexer;

use lalrpop_util::lalrpop_mod;
use serde::Deserialize;
use snmp::SnmpResult;

lalrpop_mod!(grammar);

#[derive(Deserialize, Debug)]
pub struct Metric {
    pub name: String,
    pub prefix: Option<String>,
    value: String,
    uom: Option<String>,
    min: Option<f32>,
    max: Option<f32>,
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

    pub fn eval(&self, expr: &str) -> f32 {
        2.0_f32
    }
}

mod Test {
    use super::*;

    #[test]
    fn term() {
        let lexer = lexer::Lexer::new("123");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 123_f32);
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
        assert!(res.unwrap() == 3_f32);

        let lexer = lexer::Lexer::new("1 + 2 - 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 0_f32);

        let lexer = lexer::Lexer::new("1 - 2 + 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 2_f32);

        let lexer = lexer::Lexer::new("1 - (2 + 3)");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == -4_f32);

        let lexer = lexer::Lexer::new("1 - (2 + (3 - (4 + (5 - (6 + 7)))))");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == -8_f32);
    }

    #[test]
    fn product() {
        let lexer = lexer::Lexer::new("2 * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 6_f32);

        let lexer = lexer::Lexer::new("1 + 2 * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 7_f32);

        let lexer = lexer::Lexer::new("(1 + 2) * 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 9_f32);

        let lexer = lexer::Lexer::new("2 * 3 * 4");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 24_f32);

        let lexer = lexer::Lexer::new("2 * 3 / 2");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 3_f32);

        // We have an issue with 2/0, I know it but we'll fix it later.
    }

    #[test]
    fn sum_product() {
        let lexer = lexer::Lexer::new("1 + (3 + 2 * 3) / 3");
        let res = grammar::ExprParser::new().parse(lexer);
        assert!(res.is_ok());
        assert!(res.unwrap() == 4_f32);
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
