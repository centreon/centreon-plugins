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
    Scalar(f64),
    StrVector(Vec<String>),
}

impl std::ops::Add for ExprResult {
    type Output = ExprResult;

    fn add(self, other: Self) -> Self::Output {
        match (self, other) {
            (ExprResult::Scalar(a), ExprResult::Scalar(b)) => ExprResult::Scalar(a + b),
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
                    if len_a > len_b {
                        let mut result = a.clone();
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] += value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b.clone();
                        for (idx, value) in a.iter().enumerate() {
                            result[idx] += value;
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Scalar(a), ExprResult::Vector(b)) => {
                let mut result = b.clone();
                for value in result.iter_mut() {
                    *value += a;
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Scalar(b)) => {
                let mut result = a.clone();
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
            (ExprResult::Scalar(a), ExprResult::Scalar(b)) => ExprResult::Scalar(a - b),
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
                    if len_a > len_b {
                        let mut result = a.clone();
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] -= value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b.clone();
                        for (idx, value) in a.iter().enumerate() {
                            result[idx] -= value;
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Scalar(a), ExprResult::Vector(b)) => {
                let mut result = vec![0_f64; b.len()];
                for (idx, value) in result.iter_mut().enumerate() {
                    *value = a - b[idx];
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Scalar(b)) => {
                let mut result = a.clone();
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
            (ExprResult::Scalar(a), ExprResult::Scalar(b)) => ExprResult::Scalar(a * b),
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
                    if len_a > len_b {
                        let mut result = a.clone();
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] *= value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b.clone();
                        for (idx, value) in a.iter().enumerate() {
                            result[idx] *= value;
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Scalar(a), ExprResult::Vector(b)) => {
                let mut result = b.clone();
                for value in result.iter_mut() {
                    *value *= a;
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Scalar(b)) => {
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
            (ExprResult::Scalar(a), ExprResult::Scalar(b)) => ExprResult::Scalar(a / b),
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
                    if len_a > len_b {
                        let mut result = a.clone();
                        for (idx, value) in b.iter().enumerate() {
                            result[idx] /= value;
                        }
                        ExprResult::Vector(result)
                    } else {
                        let mut result = b.clone();
                        for (idx, value) in a.iter().enumerate() {
                            result[idx] /= value;
                        }
                        ExprResult::Vector(result)
                    }
                }
            }
            (ExprResult::Scalar(a), ExprResult::Vector(b)) => {
                let mut result = vec![0_f64; b.len()];
                for (idx, value) in result.iter_mut().enumerate() {
                    *value = a / b[idx];
                }
                ExprResult::Vector(result)
            }
            (ExprResult::Vector(a), ExprResult::Scalar(b)) => {
                let mut result = a.clone();
                for value in result.iter_mut() {
                    *value /= b;
                }
                ExprResult::Vector(result)
            }
            _ => panic!("Invalid operation"),
        }
    }
}

impl<'input> Expr<'input> {
    pub fn eval(&self, collect: &Vec<SnmpResult>) -> ExprResult {
        match self {
            Expr::Number(n) => ExprResult::Scalar(*n),
            Expr::Id(key) => {
                let k = str::from_utf8(key).unwrap();
                println!("Evaluation of Id '{}'", k);
                for result in collect {
                    let item = &result.items[k];
                    match item {
                        ExprResult::Vector(n) => {
                            if n.len() == 1 {
                                println!("value {}", n[0]);
                                return ExprResult::Scalar(n[0]);
                            } else {
                                println!("value {:?}", n);
                                return ExprResult::Vector(n.clone());
                            }
                        }
                        _ => panic!("Should be a number"),
                    }
                }
                ExprResult::Scalar(0.0)
            }
            Expr::OpPlus(left, right) => left.eval(collect) + right.eval(collect),
            Expr::OpMinus(left, right) => left.eval(collect) - right.eval(collect),
            Expr::OpStar(left, right) => left.eval(collect) * right.eval(collect),
            Expr::OpSlash(left, right) => left.eval(collect) / right.eval(collect),
            Expr::Fn(func, expr) => {
                let v = expr.eval(collect);
                match func {
                    Func::Average => match v {
                        ExprResult::Scalar(n) => ExprResult::Scalar(n),
                        ExprResult::Vector(v) => {
                            let sum = v.iter().sum::<f64>();
                            ExprResult::Scalar(sum / v.len() as f64)
                        }
                        _ => panic!("Invalid operation"),
                    },
                    Func::Min => match v {
                        ExprResult::Scalar(n) => ExprResult::Scalar(n),
                        ExprResult::Vector(v) => {
                            let min = v.iter().cloned().fold(f64::INFINITY, f64::min);
                            ExprResult::Scalar(min)
                        }
                        _ => panic!("Invalid operation"),
                    },
                    Func::Max => match v {
                        ExprResult::Scalar(n) => ExprResult::Scalar(n),
                        ExprResult::Vector(v) => {
                            let max = v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
                            ExprResult::Scalar(max)
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
