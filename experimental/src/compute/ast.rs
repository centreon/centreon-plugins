use log::{debug, info, trace, warn};
use snmp::SnmpResult;
use std::str;

#[derive(Debug)]
pub enum Expr<'input> {
    Id(&'input [u8]),
    Number(f64),
    OpPlus(Box<Expr<'input>>, Box<Expr<'input>>),
    OpMinus(Box<Expr<'input>>, Box<Expr<'input>>),
    OpStar(Box<Expr<'input>>, Box<Expr<'input>>),
    OpSlash(Box<Expr<'input>>, Box<Expr<'input>>),
    Fn(Func, Box<Expr<'input>>),
}

#[derive(Debug)]
pub enum Func {
    Average,
    Min,
    Max,
}

#[derive(Debug)]
pub enum ExprResult {
    Vector(Vec<f64>),
    Number(f64),
    StrVector(Vec<String>),
    Str(String),
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
    pub fn join(&mut self, other: &ExprResult) {
        match self {
            ExprResult::Empty => match other {
                ExprResult::StrVector(vv) => {
                    *self = ExprResult::StrVector(vv.clone());
                }
                ExprResult::Str(s) => {
                    *self = ExprResult::Str(s.clone());
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
                ExprResult::Str(ss) => {
                    *s = format!("{}{}", s, ss);
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
    pub fn eval(&self, collect: &Vec<SnmpResult>) -> ExprResult {
        match self {
            Expr::Number(n) => ExprResult::Number(*n),
            Expr::Id(key) => {
                let k = str::from_utf8(key).unwrap();
                for result in collect {
                    match result.items.get(k) {
                        Some(item) => match item {
                            ExprResult::Vector(n) => {
                                if n.len() == 1 {
                                    info!("ID '{}' has value {}", k, n[0]);
                                    return ExprResult::Number(n[0]);
                                } else {
                                    info!("ID '{}' has value {:?}", k, n);
                                    return ExprResult::Vector(n.clone());
                                }
                            }
                            _ => panic!("Should be a number"),
                        },
                        None => continue,
                    }
                }
                ExprResult::Number(0.0)
            }
            Expr::OpPlus(left, right) => left.eval(collect) + right.eval(collect),
            Expr::OpMinus(left, right) => left.eval(collect) - right.eval(collect),
            Expr::OpStar(left, right) => left.eval(collect) * right.eval(collect),
            Expr::OpSlash(left, right) => left.eval(collect) / right.eval(collect),
            Expr::Fn(func, expr) => {
                let v = expr.eval(collect);
                match func {
                    Func::Average => match v {
                        ExprResult::Number(n) => ExprResult::Number(n),
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
                                return ExprResult::Number(sum / count as f64);
                            } else {
                                return ExprResult::Number(f64::NAN);
                            }
                        }
                        _ => panic!("Invalid operation"),
                    },
                    Func::Min => match v {
                        ExprResult::Number(n) => ExprResult::Number(n),
                        ExprResult::Vector(v) => {
                            let min = v.iter().cloned().fold(f64::INFINITY, f64::min);
                            ExprResult::Number(min)
                        }
                        _ => panic!("Invalid operation"),
                    },
                    Func::Max => match v {
                        ExprResult::Number(n) => ExprResult::Number(n),
                        ExprResult::Vector(v) => {
                            let max = v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
                            ExprResult::Number(max)
                        }
                        _ => panic!("Invalid operation"),
                    },
                }
            }
        }
    }

    pub fn eval_as_str(&self) -> &[u8] {
        if let Expr::Id(id) = self {
            return id;
        } else {
            return b"Bad value";
        }
    }
}
