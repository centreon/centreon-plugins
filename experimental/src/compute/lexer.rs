use log::debug;
use std::str;

pub type Spanned<Tok, Loc, Error> = Result<(Loc, Tok, Loc), Error>;

#[derive(Debug, PartialEq, Clone)]
pub enum Tok {
    Num(f32),
    Id,
    OpStar,
    OpSlash,
    OpPlus,
    OpMinus,
    LParen,
    RParen,
}

#[derive(Debug, PartialEq)]
pub enum LexicalError {
    NotPossible,
    // Not possible
}

#[derive(Debug)]
pub struct Lexer<'input> {
    chars: &'input str,
    offset: usize,
}

impl<'input> Lexer<'input> {
    pub fn new(input: &'input str) -> Self {
        Lexer {
            chars: input,
            offset: 0,
        }
    }

    fn number(&mut self, start: usize, chars: &[u8]) -> Option<Spanned<Tok, usize, LexicalError>> {
        // Consume digits and decimal points
        let mut end = start;
        let mut done = false;
        for c in chars[(start + 1)..].iter() {
            end += 1;
            if !(*c).is_ascii_digit() && *c != b'.' {
                done = true;
                break;
            }
        }
        if !done {
            end = chars.len();
        }

        debug!(
            "Token Number from {} to {} with value '{}'",
            start,
            end,
            str::from_utf8(&chars[start..end]).unwrap_or("Bad value")
        );
        self.offset = end;
        let value = str::from_utf8(&chars[start..end])
            .unwrap_or("Bad value")
            .parse::<f32>()
            .unwrap_or(0.0);
        Some(Ok((start, Tok::Num(value), end)))
    }

    fn identifier(
        &mut self,
        start: usize,
        chars: &[u8],
    ) -> Option<Spanned<Tok, usize, LexicalError>> {
        // Consume identifier
        let mut end = start;
        let mut done = false;
        for c in chars[(start + 1)..].iter() {
            end += 1;
            if !c.is_ascii_alphanumeric() && *c != b'_' {
                done = true;
                break;
            }
        }
        if !done {
            end = chars.len();
        }
        debug!(
            "Token Identifier from {} to {} with value '{}'",
            start,
            end,
            str::from_utf8(&chars[start..end]).unwrap_or("Bad value")
        );
        self.offset = end;
        Some(Ok((start, Tok::Id, end)))
    }
}

impl<'input> Iterator for Lexer<'input> {
    type Item = Spanned<Tok, usize, LexicalError>;

    fn next(&mut self) -> Option<Self::Item> {
        for (i, c) in self.chars.as_bytes().iter().enumerate().skip(self.offset) {
            match *c {
                b' ' | b'\t' => continue,
                b'*' => {
                    self.offset = i + 1;
                    return Some(Ok((i, Tok::OpStar, i + 1)));
                }
                b'/' => {
                    self.offset = i + 1;
                    return Some(Ok((i, Tok::OpSlash, i + 1)));
                }
                b'+' => {
                    self.offset = i + 1;
                    return Some(Ok((i, Tok::OpPlus, i + 1)));
                }
                b'-' => {
                    self.offset = i + 1;
                    return Some(Ok((i, Tok::OpMinus, i + 1)));
                }
                b'(' => {
                    self.offset = i + 1;
                    return Some(Ok((i, Tok::LParen, i + 1)));
                }
                b')' => {
                    self.offset = i + 1;
                    return Some(Ok((i, Tok::RParen, i + 1)));
                }
                b'0'..=b'9' => {
                    // Consume digits and decimal points
                    return self.number(i, &self.chars.as_bytes());
                }
                b'a'..=b'z' | b'A'..=b'Z' | b'_' => {
                    return self.identifier(i, &self.chars.as_bytes());
                }
                _ => {
                    // Unknown character
                    debug!("Unknown character at {}: '{}'", i, *c as char);
                    self.offset = i + 1;
                    return Some(Err(LexicalError::NotPossible));
                }
            }
        }
        // No more characters to process
        return None;
    }
}

mod Test {
    use super::*;

    #[test]
    fn test_lexer_num_id_num() {
        let input = "123 abc 456";
        let mut lexer = Lexer::new(input);
        assert_eq!(lexer.next(), Some(Ok((0, Tok::Num(123_f32), 3))));
        assert_eq!(lexer.next(), Some(Ok((4, Tok::Id, 7))));
        assert_eq!(lexer.next(), Some(Ok((8, Tok::Num(456_f32), 11))));
        assert_eq!(lexer.next(), None);
    }

    #[test]
    fn test_lexer_id_num_id() {
        let input = "abc 123 def";
        let mut lexer = Lexer::new(input);
        assert_eq!(lexer.next(), Some(Ok((0, Tok::Id, 3))));
        assert_eq!(lexer.next(), Some(Ok((4, Tok::Num(123_f32), 7))));
        assert_eq!(lexer.next(), Some(Ok((8, Tok::Id, 11))));
    }

    #[test]
    fn test_lexer_num_op() {
        let input = "1+2*3";
        let mut lexer = Lexer::new(input);
        assert_eq!(lexer.next(), Some(Ok((0, Tok::Num(1_f32), 1))));
        assert_eq!(lexer.next(), Some(Ok((1, Tok::OpPlus, 2))));
        assert_eq!(lexer.next(), Some(Ok((2, Tok::Num(2_f32), 3))));
        assert_eq!(lexer.next(), Some(Ok((3, Tok::OpStar, 4))));
        assert_eq!(lexer.next(), Some(Ok((4, Tok::Num(3_f32), 5))));
        assert_eq!(lexer.next(), None);
    }
}
