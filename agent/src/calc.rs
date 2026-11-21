//! Ferramenta `calc` sandboxed (Etapa 40).
//! Charset fechado; parser recursivo; sem Command/rede/FS.

/// Valida charset e avalia expressão aritmética pura.
pub fn eval_expr(expr: &str) -> Result<f64, String> {
    let trimmed = expr.trim();
    if trimmed.is_empty() {
        return Err("calc: expressão vazia".into());
    }
    for c in trimmed.chars() {
        if !(c.is_ascii_digit()
            || c == '.'
            || c == '+'
            || c == '-'
            || c == '*'
            || c == '/'
            || c == '('
            || c == ')'
            || c == ' ')
        {
            return Err(format!("calc: charset inválido (byte/char '{c}')"));
        }
    }
    let chars: Vec<char> = trimmed.chars().filter(|c| *c != ' ').collect();
    let mut i = 0usize;
    let val = parse_expr(&chars, &mut i)?;
    if i != chars.len() {
        return Err("calc: lixo após expressão".into());
    }
    if !val.is_finite() {
        return Err("calc: resultado não finito".into());
    }
    Ok(val)
}

fn parse_expr(chars: &[char], i: &mut usize) -> Result<f64, String> {
    let mut left = parse_term(chars, i)?;
    while *i < chars.len() {
        match chars[*i] {
            '+' => {
                *i += 1;
                left += parse_term(chars, i)?;
            }
            '-' => {
                *i += 1;
                left -= parse_term(chars, i)?;
            }
            _ => break,
        }
    }
    Ok(left)
}

fn parse_term(chars: &[char], i: &mut usize) -> Result<f64, String> {
    let mut left = parse_factor(chars, i)?;
    while *i < chars.len() {
        match chars[*i] {
            '*' => {
                *i += 1;
                left *= parse_factor(chars, i)?;
            }
            '/' => {
                *i += 1;
                let right = parse_factor(chars, i)?;
                if right == 0.0 {
                    return Err("calc: divisão por zero".into());
                }
                left /= right;
            }
            _ => break,
        }
    }
    Ok(left)
}

fn parse_factor(chars: &[char], i: &mut usize) -> Result<f64, String> {
    if *i >= chars.len() {
        return Err("calc: fator incompleto".into());
    }
    match chars[*i] {
        '+' => {
            *i += 1;
            parse_factor(chars, i)
        }
        '-' => {
            *i += 1;
            Ok(-parse_factor(chars, i)?)
        }
        '(' => {
            *i += 1;
            let v = parse_expr(chars, i)?;
            if *i >= chars.len() || chars[*i] != ')' {
                return Err("calc: ')' esperado".into());
            }
            *i += 1;
            Ok(v)
        }
        c if c.is_ascii_digit() || c == '.' => parse_number(chars, i),
        other => Err(format!("calc: token inesperado '{other}'")),
    }
}

fn parse_number(chars: &[char], i: &mut usize) -> Result<f64, String> {
    let start = *i;
    while *i < chars.len() && (chars[*i].is_ascii_digit() || chars[*i] == '.') {
        *i += 1;
    }
    if start == *i {
        return Err("calc: número esperado".into());
    }
    let s: String = chars[start..*i].iter().collect();
    s.parse::<f64>()
        .map_err(|_| format!("calc: número inválido '{s}'"))
}

#[cfg(test)]
mod tests {
    use super::eval_expr;

    #[test]
    fn proof_expr() {
        assert!((eval_expr("1+2*3").unwrap() - 7.0).abs() < 1e-9);
    }

    #[test]
    fn rejects_letters() {
        assert!(eval_expr("1+a").is_err());
    }

    #[test]
    fn rejects_semicolon() {
        assert!(eval_expr("1;2").is_err());
    }

    #[test]
    fn div_zero() {
        assert!(eval_expr("1/0").is_err());
    }
}
