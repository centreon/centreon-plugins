//! Abstract syntax tree and expression evaluation.

use crate::snmp::SnmpResult;
use log::{info, trace, warn};
use std::str;

/// An expression node in the AST.
#[derive(Debug)]
pub enum Expr<'input> {
    /// A variable identifier (e.g., parsed from `{varname}`).
    Id(&'input [u8]),
    /// A numeric constant.
    Number(f64),
    /// Addition of two expressions.
    OpPlus(Box<Expr<'input>>, Box<Expr<'input>>),
    /// Subtraction of two expressions.
    OpMinus(Box<Expr<'input>>, Box<Expr<'input>>),
    /// Multiplication of two expressions.
    OpStar(Box<Expr<'input>>, Box<Expr<'input>>),
    /// Division of two expressions.
    OpSlash(Box<Expr<'input>>, Box<Expr<'input>>),
    /// A function call (e.g., `Average()`, `Min()`, `Max()`).
    Fn(Func, Box<Expr<'input>>),
}

/// Aggregation functions for collapsing vectors to scalars.
#[derive(Debug)]
pub enum Func {
    /// Compute the arithmetic mean, skipping NaN values.
    Average,
    /// Compute the minimum value.
    Min,
    /// Compute the maximum value.
    Max,
}

/// Result of evaluating an expression: either a numeric value/vector or a string.
#[derive(Debug)]
pub enum ExprResult {
    /// A vector of floating-point values.
    Vector(Vec<f64>),
    /// A single floating-point scalar.
    Number(f64),
    /// A vector of strings.
    StrVector(Vec<String>),
    /// A single string.
    Str(String),
    /// No value (used as a sentinel during expression building).
    Empty,
}

impl std::ops::Add for ExprResult {
    type Output = ExprResult;

    fn add(self, other: Self) -> Self::Output {
        match (self, other) {
            (ExprResult::Number(a), ExprResult::Number(b)) => ExprResult::Number(a + b),
            (ExprResult::Vector(a), ExprResult::Vector(b)) => {
                let len_a = a.len();
                let len_b = b.len();
                if len_a == len_b {
                    let mut result = Vec::with_capacity(len_a);
                    for i in 0..len_a {
                        result.push(a[i] + b[i]);
                    }
                    ExprResult::Vector(result)
                } else {
                    warn!(
                        "Trying to add to arrays of different lengths: {} and {}",
                        len_a, len_b
                    );
                    if len_a > len_b {
                        let mut result = a;
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] += value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b;
                        for (idx, value) in a.iter().enumerate() {
                            result[idx] += value;
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Number(a), ExprResult::Vector(b)) => {
                let mut result = b;
                for value in result.iter_mut() {
                    *value += a;
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Number(b)) => {
                let mut result = a;
                for value in result.iter_mut() {
                    *value += b;
                }
                ExprResult::Vector(result)
            }
            _ => panic!("Invalid operation"),
        }
    }
}

impl std::ops::Sub for ExprResult {
    type Output = ExprResult;

    fn sub(self, other: Self) -> Self::Output {
        match (self, other) {
            (ExprResult::Number(a), ExprResult::Number(b)) => ExprResult::Number(a - b),
            (ExprResult::Vector(a), ExprResult::Vector(b)) => {
                let len_a = a.len();
                let len_b = b.len();
                if len_a == len_b {
                    let mut result = Vec::with_capacity(len_a);
                    for i in 0..len_a {
                        result.push(a[i] - b[i]);
                    }
                    ExprResult::Vector(result)
                } else {
                    warn!(
                        "Trying to subtract arrays of different lengths: {} and {}",
                        len_a, len_b
                    );
                    if len_a > len_b {
                        let mut result = a;
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] -= value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b;
                        for (idx, value) in result.iter_mut().enumerate() {
                            if idx < a.len() {
                                *value = a[idx] - *value;
                            } else {
                                *value = -*value;
                            }
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Number(a), ExprResult::Vector(b)) => {
                let mut result = vec![0_f64; b.len()];
                for (idx, value) in result.iter_mut().enumerate() {
                    *value = a - b[idx];
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Number(b)) => {
                let mut result = a;
                for value in result.iter_mut() {
                    *value -= b;
                }
                ExprResult::Vector(result)
            }
            _ => panic!("Invalid operation"),
        }
    }
}

impl std::ops::Mul for ExprResult {
    type Output = ExprResult;

    fn mul(self, other: Self) -> Self::Output {
        match (self, other) {
            (ExprResult::Number(a), ExprResult::Number(b)) => ExprResult::Number(a * b),
            (ExprResult::Vector(a), ExprResult::Vector(b)) => {
                let len_a = a.len();
                let len_b = b.len();
                if len_a == len_b {
                    let mut result = Vec::with_capacity(len_a);
                    for i in 0..len_a {
                        result.push(a[i] * b[i]);
                    }
                    ExprResult::Vector(result)
                } else {
                    warn!(
                        "Trying to multiply arrays of different lengths: {} and {}",
                        len_a, len_b
                    );
                    if len_a > len_b {
                        let mut result = a;
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] *= value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b;
                        for (idx, value) in a.iter().enumerate() {
                            result[idx] *= value;
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Number(a), ExprResult::Vector(b)) => {
                let mut result = b.clone();
                for value in result.iter_mut() {
                    *value *= a;
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Number(b)) => {
                let mut result = a.clone();
                for value in result.iter_mut() {
                    *value *= b;
                }
                ExprResult::Vector(result)
            }
            _ => panic!("Invalid operation"),
        }
    }
}

impl std::ops::Div for ExprResult {
    type Output = ExprResult;

    fn div(self, other: Self) -> Self::Output {
        match (self, other) {
            (ExprResult::Number(a), ExprResult::Number(b)) => ExprResult::Number(a / b),
            (ExprResult::Vector(a), ExprResult::Vector(b)) => {
                let len_a = a.len();
                let len_b = b.len();
                if len_a == len_b {
                    let mut result = Vec::with_capacity(len_a);
                    for i in 0..len_a {
                        result.push(a[i] / b[i]);
                    }
                    ExprResult::Vector(result)
                } else {
                    warn!(
                        "Trying to divide arrays of different lengths: {} and {}",
                        len_a, len_b
                    );
                    if len_a > len_b {
                        let mut result = a;
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] /= value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b;
                        for (idx, value) in result.iter_mut().enumerate() {
                            if idx < a.len() {
                                *value = a[idx] / *value;
                            } else {
                                *value = 1_f64 / *value;
                            }
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Number(a), ExprResult::Vector(b)) => {
                let mut result = vec![0_f64; b.len()];
                for (idx, value) in result.iter_mut().enumerate() {
                    *value = a / b[idx];
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Number(b)) => {
                let mut result = a;
                for value in result.iter_mut() {
                    *value /= b;
                }
                ExprResult::Vector(result)
            }
            _ => panic!("Invalid operation"),
        }
    }
}

impl ExprResult {
    /// Concatenates `other` into `self` for string interpolation.
    ///
    /// When `self` is a string vector and `other` is a numeric vector, converts
    /// the numbers to strings before concatenation, padding to match lengths
    /// where necessary.
    pub fn join(&mut self, other: &ExprResult) {
        trace!("[join] self: {:?} - other: {:?}", &self, &other);
        match self {
            ExprResult::Empty => match other {
                ExprResult::StrVector(vv) => {
                    *self = ExprResult::StrVector(vv.clone());
                }
                ExprResult::Str(s) => {
                    *self = ExprResult::Str(s.clone());
                }
                ExprResult::Vector(vv) => {
                    *self = ExprResult::StrVector(
                        vv.iter().map(|n| crate::output::float_string(n)).collect(),
                    );
                }
                _ => panic!("Unable to join objects others than strings"),
            },
            ExprResult::StrVector(v) => match other {
                ExprResult::StrVector(vv) => {
                    if v.len() != vv.len() {
                        warn!(
                            "Trying to join arrays of different lengths: {} and {}",
                            v.len(),
                            vv.len()
                        );
                        if v.len() < vv.len() {
                            v.resize(vv.len(), "".to_string());
                        }
                    }
                    for (key, value) in v.iter_mut().enumerate() {
                        value.push_str(vv.get(key).unwrap_or(&"".to_string()));
                    }
                }
                ExprResult::Vector(vv) => {
                    if v.len() != vv.len() {
                        warn!(
                            "Trying to join arrays of different lengths: {} and {}",
                            v.len(),
                            vv.len()
                        );
                        if v.len() < vv.len() {
                            v.resize(vv.len(), "".to_string());
                        }
                    }
                    for (key, value) in v.iter_mut().enumerate() {
                        if let Some(val) = vv.get(key) {
                            value.push_str(&val.to_string());
                        }
                    }
                }
                ExprResult::Str(s) => {
                    *v = v.iter().map(|a| format!("{}{}", a, s)).collect();
                }
                _ => panic!("Unable to join objects others than strings"),
            },
            ExprResult::Str(s) => match other {
                ExprResult::StrVector(vv) => {
                    *self =
                        ExprResult::StrVector(vv.iter().map(|a| format!("{}{}", s, a)).collect());
                }
                ExprResult::Vector(vv) => {
                    *self =
                        ExprResult::StrVector(vv.iter().map(|a| format!("{}{}", s, a)).collect());
                }
                ExprResult::Str(ss) => {
                    *s = format!("{}{}", s, ss);
                }
                ExprResult::Number(n) => {
                    trace!("[join] n: {:?}", &n);
                    *s = format!("{}{}", s, crate::output::float_string(n));
                }
                _ => panic!("Unable to join objects others than strings"),
            },
            _ => {
                panic!("Unable to join objects that are not strings");
            }
        }
    }
}

impl<'input> Expr<'input> {
    /// Check that all macros exist in the collected results
    pub fn validate_macros(&self, collect: &Vec<SnmpResult>) -> Result<(), String> {
        match self {
            Expr::Id(key) => {
                let k = str::from_utf8(key).unwrap();
                for result in collect {
                    if result.items.contains_key(k) {
                        return Ok(());
                    }
                }
                Err(format!("Undefined macro in expression: {{{}}}", k))
            }
            Expr::Number(_) => Ok(()),
            Expr::OpPlus(left, right)
            | Expr::OpMinus(left, right)
            | Expr::OpStar(left, right)
            | Expr::OpSlash(left, right) => {
                left.validate_macros(collect)?;
                right.validate_macros(collect)?;
                Ok(())
            }
            Expr::Fn(_, expr) => expr.validate_macros(collect),
        }
    }

    /// Recursively evaluates this expression against the collected SNMP results.
    ///
    /// Resolves identifiers by searching through the `collect` vector, applies
    /// operators element-wise for vectors, and evaluates functions.
    pub fn eval(&self, collect: &Vec<SnmpResult>) -> Result<ExprResult, String> {
        match self {
            Expr::Number(n) => Ok(ExprResult::Number(*n)),
            Expr::Id(key) => {
                let k = str::from_utf8(key).unwrap();
                for result in collect {
                    match result.items.get(k) {
                        Some(item) => match item {
                            ExprResult::Vector(n) => {
                                if n.len() == 1 {
                                    info!("ID '{}' has value {}", k, n[0]);
                                    return Ok(ExprResult::Number(n[0]));
                                } else {
                                    info!("ID '{}' has value {:?}", k, n);
                                    return Ok(ExprResult::Vector(n.clone()));
                                }
                            }
                            _ => panic!("Should be a number"),
                        },
                        None => continue,
                    }
                }
                Ok(ExprResult::Number(0.0))
            }
            Expr::OpPlus(left, right) => Ok(left.eval(collect)? + right.eval(collect)?),
            Expr::OpMinus(left, right) => Ok(left.eval(collect)? - right.eval(collect)?),
            Expr::OpStar(left, right) => Ok(left.eval(collect)? * right.eval(collect)?),
            Expr::OpSlash(left, right) => Ok(left.eval(collect)? / right.eval(collect)?),
            Expr::Fn(func, expr) => {
                let v = expr.eval(collect)?;
                match func {
                    Func::Average => match v {
                        ExprResult::Number(n) => Ok(ExprResult::Number(n)),
                        ExprResult::Vector(v) => {
                            let mut sum = 0.0;
                            let mut count = 0;
                            for value in v {
                                if !value.is_nan() {
                                    sum += value;
                                    count += 1;
                                }
                            }
                            if count > 0 {
                                Ok(ExprResult::Number(sum / count as f64))
                            } else {
                                Ok(ExprResult::Number(f64::NAN))
                            }
                        }
                        _ => panic!("Invalid operation"),
                    },
                    Func::Min => match v {
                        ExprResult::Number(n) => Ok(ExprResult::Number(n)),
                        ExprResult::Vector(v) => {
                            let min = v.iter().cloned().fold(f64::INFINITY, f64::min);
                            Ok(ExprResult::Number(min))
                        }
                        _ => panic!("Invalid operation"),
                    },
                    Func::Max => match v {
                        ExprResult::Number(n) => Ok(ExprResult::Number(n)),
                        ExprResult::Vector(v) => {
                            let max = v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
                            Ok(ExprResult::Number(max))
                        }
                        _ => panic!("Invalid operation"),
                    },
                }
            }
        }
    }

    /// Returns the byte representation of an identifier expression, or a default error message.
    pub fn eval_as_str(&self) -> &[u8] {
        if let Expr::Id(id) = self {
            return id;
        } else {
            return b"Bad value";
        }
    }
}
