use iced::widget::{rich_text, span};
use iced::{Color, Element, Font};

#[derive(Clone, Copy)]
pub enum Language {
    Wgsl,
}

#[derive(Clone, Copy)]
enum Tok {
    Keyword,
    Type,
    Attribute,
    Number,
    Comment,
    // Str,
    Punct,
    Ident,
}

fn color(t: Tok) -> Color {
    match t {
        Tok::Keyword => Color::from_rgb8(0xC5, 0x92, 0xD6), // purple
        Tok::Type => Color::from_rgb8(0x4E, 0xC9, 0xB0),    // teal
        Tok::Attribute => Color::from_rgb8(0xDC, 0xDC, 0xAA), // yellow
        Tok::Number => Color::from_rgb8(0xB5, 0xCE, 0xA8),  // green
        Tok::Comment => Color::from_rgb8(0x6A, 0x99, 0x55), // dim green
        // Tok::Str => Color::from_rgb8(0xCE, 0x91, 0x78),     // orange
        Tok::Punct => Color::from_rgb8(0xAB, 0xB2, 0xBF),
        Tok::Ident => Color::from_rgb8(0xD4, 0xD4, 0xD4),
    }
}

fn with_opacity(c: Color, opacity: f32) -> Color {
    Color {
        r: c.r,
        g: c.g,
        b: c.b,
        a: opacity,
    }
}

use iced::widget::text::Span;

pub fn code_view<'a, M: 'static + Clone>(
    src: &str,
    opacity: f32,
    lang: Language,
) -> Element<'a, M> {
    let spans: Vec<Span<'a, M>> = match lang {
        Language::Wgsl => tokenize_wgsl(src),
    }
    .into_iter()
    .map(|(text, tok)| {
        span(text)
            .color(with_opacity(color(tok), opacity))
            .font(Font::MONOSPACE)
    })
    .collect();

    rich_text(spans).font(Font::MONOSPACE).size(18).into()
}

fn tokenize_wgsl(src: &str) -> Vec<(String, Tok)> {
    const KEYWORDS: &[&str] = &[
        "fn", "let", "var", "const", "struct", "return", "if", "else", "for", "while", "loop",
        "break", "continue", "switch", "case", "default", "discard", "true", "false",
    ];
    const TYPES: &[&str] = &[
        "f32",
        "i32",
        "u32",
        "bool",
        "vec2",
        "vec3",
        "vec4",
        "mat2x2",
        "mat3x3",
        "mat4x4",
        "array",
        "ptr",
        "atomic",
        "sampler",
        "texture_2d",
    ];

    let chars: Vec<char> = src.chars().collect();
    let mut out = Vec::new();
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        if c == '/' && chars.get(i + 1) == Some(&'/') {
            let start = i;
            while i < chars.len() && chars[i] != '\n' {
                i += 1;
            }
            out.push((chars[start..i].iter().collect(), Tok::Comment));
        } else if c == '/' && chars.get(i + 1) == Some(&'*') {
            let start = i;
            i += 2;
            while i < chars.len() && !(chars[i] == '*' && chars.get(i + 1) == Some(&'/')) {
                i += 1;
            }
            i = (i + 2).min(chars.len());
            out.push((chars[start..i].iter().collect(), Tok::Comment));
        } else if c == '@' {
            let start = i;
            i += 1;
            while i < chars.len() && (chars[i].is_alphanumeric() || chars[i] == '_') {
                i += 1;
            }
            out.push((chars[start..i].iter().collect(), Tok::Attribute));
        } else if c.is_alphabetic() || c == '_' {
            let start = i;
            while i < chars.len() && (chars[i].is_alphanumeric() || chars[i] == '_') {
                i += 1;
            }
            let word: String = chars[start..i].iter().collect();
            let tok = if KEYWORDS.contains(&word.as_str()) {
                Tok::Keyword
            } else if TYPES.contains(&word.as_str()) {
                Tok::Type
            } else {
                Tok::Ident
            };
            out.push((word, tok));
        } else if c.is_ascii_digit() {
            let start = i;
            while i < chars.len() && (chars[i].is_alphanumeric() || chars[i] == '.') {
                i += 1;
            }
            out.push((chars[start..i].iter().collect(), Tok::Number));
        } else {
            // whitespace + punctuation: keep as-is so layout is preserved
            let start = i;
            while i < chars.len()
                && !chars[i].is_alphanumeric()
                && chars[i] != '_'
                && chars[i] != '@'
                && !(chars[i] == '/'
                    && (chars.get(i + 1) == Some(&'/') || chars.get(i + 1) == Some(&'*')))
            {
                i += 1;
            }
            out.push((chars[start..i].iter().collect(), Tok::Punct));
        }
    }
    out
}
