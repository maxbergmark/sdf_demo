use iced::{
    Border, Color, Element, Font, Length, Size,
    widget::{container, responsive, space, stack, text},
};
use iced_glass::widget::InnerContent;
use iced_glass::{
    glass_stack,
    widget::{StackOffset, container as glass_container},
};

use crate::Message;

#[derive(Debug, Clone)]
pub struct Slide {
    pub code: Option<&'static str>,
    #[allow(unused)]
    pub equation: Option<&'static str>,
    pub shape: u32,
    pub a: f32,
    pub overlay: Option<fn(blend: f32, t: f32) -> Element<'static, Message>>,
}

pub const SLIDES: &[Slide] = &[
    Slide {
        code: Some(
            r#"fn circle(p: vec2, r: f32) -> f32 {
    return length(p) - r;
}"#,
        ),
        equation: Some(
            r#"f: RR^2 -> RR \
               f(arrow(p)) = |arrow(p)| - r "#,
        ),
        shape: 0,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn translate(p: vec2, offset: vec2) -> vec2 {
    return p - offset;
}
"#,
        ),
        equation: None,
        shape: 0,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn rectangle(p: vec2, size: vec2) -> f32 {
    let d = abs(p)-size;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0);
}"#,
        ),
        equation: None,
        shape: 1,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn round(d: f32, r: f32) -> f32 {
    return d - r;
}"#,
        ),
        equation: None,
        shape: 2,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn rounded_rectangle(p: vec2, size: vec2, r: f32) -> f32 {
    return rectangle(p, size - vec2(r)) - r;
}"#,
        ),
        equation: None,
        shape: 2,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn sunlight(d: f32, g: vec2, color: vec4) -> vec4 {
    let intensity = sun_intensity(d, g); // math goes here
    return color * intensity;
}"#,
        ),
        equation: None,
        shape: 3,
        a: 0.2,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn add(d1: f32, d2: f32) -> f32 {
    return min(d1, d2);
}"#,
        ),
        equation: None,
        shape: 4,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn smooth_add( a: f32, b: f32, k: f32 ) -> f32 {
    let h = max(4*k-abs(a-b),0);
    return min(a, b) - h*h/(k*16);
}"#,
        ),
        equation: None,
        shape: 4,
        a: 0.05,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn smooth_add( a: f32, b: f32, k: f32 ) -> f32 {
    let h = max(4*k-abs(a-b),0);
    return min(a, b) - h*h/(k*16);
}"#,
        ),
        equation: None,
        shape: 4,
        a: 0.5,
        overlay: None,
    },
    Slide {
        code: None,
        equation: None,
        shape: 6,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: None,
        equation: None,
        shape: 6,
        a: 0.2,
        overlay: None,
    },
    Slide {
        code: None,
        equation: None,
        shape: 6,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn repeat(p: vec2, s: vec2) -> vec2 {
    return p - s * round(p / s);
}"#,
        ),
        equation: None,
        shape: 7,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn subtract(d1: f32, d2: f32) -> f32 {
    return max(d1, -d2);
}"#,
        ),
        equation: None,
        shape: 8,
        a: 0.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn intersect(d1: f32, d2: f32) -> f32 {
    return max(d1, d2);
}"#,
        ),
        equation: None,
        shape: 9,
        a: 0.0,
        overlay: None,
    },
    //     Slide {
    //         code: Some(
    //             r#"fn repeat_bounded(p: vec2, s: vec2, low: vec2, high: vec2) -> vec2 {
    //     return p - s * clamp(round(p / s), low, high);
    // }"#,
    //         ),
    // shape: 10,
    //         a: 0.0,
    //         overlay: None,
    //     },
    Slide {
        code: Some(
            r#"fn distort(p: vec2, d: f32, t: f32) -> f32 {
    return d + sin(t * 2 + p.x * 10 + p.y * 20) * 0.01            
}"#,
        ),
        equation: None,
        shape: 9,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn repeat_round(p: vec2, n: f32) -> vec2 {
    let angle = 2.0 * PI / n;
    let a = atan2(p.y, p.x);
    let a_fold = a - angle * round(a / angle);
    let r = length(p);
    return vec2(r * a_fold, r);
}"#,
        ),
        equation: None,
        shape: 11,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn rotate(p: vec2, angle: f32) -> vec2 {
    let c = cos(angle);
    let s = sin(angle);
    return mat2x2(c, s, -s, c) * p;
}"#,
        ),
        equation: None,
        shape: 12,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn repeat_idx(p: vec2, n: f32) -> f32 {
    let angle = 2.0 * PI / n;
    let a = atan2(p.y, p.x);
    return (n + round(a / angle)) % n;
}"#,
        ),
        equation: None,
        shape: 13,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn letter_t(p: vec2) -> f32 {
    let stem = rectangle(p + vec2(0.0, 0.0), vec2(0.1, 0.5));
    let arm = rectangle(p + vec2(0.0, 0.4), vec2(0.4, 0.1));
    return min(stem, arm);
}"#,
        ),
        equation: None,
        shape: 14,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: None,
        equation: None,
        shape: 15,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: None,
        equation: None,
        shape: 16,
        a: 1.0,
        overlay: None,
    },
    Slide {
        code: Some(
            r#"fn refract(x: f32, r: f32, n: f32, h: f32) -> f32 {
    let z = sqrt(-x * x - 2 * x * r);
    let theta = atan((x + r) / z);
    let gamma = asin(sin(theta) / n);
    return -(z + h) * tan(theta - gamma);
}"#,
        ),
        equation: None,
        shape: 17,
        a: 1.0,
        overlay: Some(|blend, _t| glass_rectangle(blend, 0.0)),
    },
    Slide {
        code: None,
        equation: None,
        shape: 17,
        a: 1.0,
        overlay: Some(|blend, _t| glass_rectangle(1.0, 20.0 * blend)),
    },
    Slide {
        code: None,
        equation: None,
        shape: 17,
        a: 1.0,
        overlay: Some(|blend, _t| {
            stack![
                glass_rectangle(1.0 - blend, 20.0),
                text_overlay(blend, 20.0, 5.0),
            ]
            .into()
        }),
    },
    Slide {
        code: None,
        equation: None,
        shape: 17,
        a: 1.0,
        overlay: Some(|blend, t| {
            let t = t * 0.2;
            responsive(move |size| {
                let r_c = size.width * 0.4 * 0.3;
                let r_e = size.width * 0.3 * 0.3 * 0.2;
                stack![
                    glass_stack!(
                        sphere(size, 0.3, 2.0, 5.0, t),
                        sphere(size, 0.4, 7.0, 3.0, t),
                        sphere(size, 0.3, 3.5, 6.0, t),
                        sphere(size, 0.4, 4.0, 7.0, t),
                    )
                    .height(Length::Fill)
                    .width(Length::Fill)
                    .glass_style(move |_| glass_style(blend, 20.0, r_e))
                    // .scrim(Color::from_rgba(1.0, 1.0, 1.0, 0.1))
                    .corner_radius(r_c)
                    .blending_factor(size.width * 0.1),
                    text_overlay(1.0 - blend, 20.0, 5.0),
                ]
            })
            .width(Length::Fill)
            .height(Length::Fill)
            .into()
        }),
    },
];

fn sphere(size: Size, r: f32, xf: f32, yf: f32, t: f32) -> InnerContent<'static, Message> {
    let scale = size.width;
    let r = r * scale * 0.3;
    container(space())
        .width(r * 2.0)
        .height(r * 2.0)
        .with_offset(
            size.width / 2.0 + 0.15 * scale * f32::sin(t * xf) - r,
            size.height / 2.0 + 0.15 * scale * f32::cos(t * yf) - r,
        )
}

fn glass_rectangle(opacity: f32, blur_radius: f32) -> Element<'static, Message> {
    responsive(move |size| {
        container(
            glass_container(space())
                .width(size.width * 0.5)
                .height(size.height * 0.35)
                .glass_style(move |_| glass_style(opacity, blur_radius, 40.0))
                .style(|_| container::Style {
                    border: Border::default().rounded(100.0),
                    ..Default::default()
                }),
        )
        .center(Length::Fill)
    })
    .width(Length::Fill)
    .height(Length::Fill)
    .into()
}

fn text_overlay(_opacity: f32, _blur_radius: f32, _edge_radius: f32) -> Element<'static, Message> {
    container(
        /*glass_*/
        text("你好")
            .size(500.0)
            // .glass_style(move |_| glass_text_style(opacity, blur_radius, edge_radius))
            .font(Font {
                family: iced::font::Family::Name("Noto Sans"),
                // family: iced::font::Family::Name("Songti SC"),
                weight: iced::font::Weight::Normal,
                stretch: iced::font::Stretch::Normal,
                style: iced::font::Style::Normal,
            }),
    )
    .center(Length::Fill)
    .style(|_| container::Style {
        border: Border::default().width(1.0).color(Color::BLACK),
        ..Default::default()
    })
    .into()
}

fn glass_style(opacity: f32, blur_radius: f32, edge_radius: f32) -> iced_glass::Style {
    iced_glass::Style {
        blur_radius,
        lightness: 0.5,
        edge_radius,
        edge_height: 200.0,
        refractive_index: 1.5,
        chromatic_aberration: 0.05,
        rim_width: 1.0,
        rim_angle: 1.0,
        opacity,
        ..Default::default()
    }
}

// fn glass_text_style(opacity: f32, blur_radius: f32, edge_radius: f32) -> iced_glass::Style {
//     iced_glass::Style {
//         blur_radius,
//         lightness: 0.5,
//         edge_radius,
//         edge_height: 200.0,
//         refractive_index: 1.5,
//         chromatic_aberration: 0.0,
//         rim_width: 1.0,
//         rim_angle: 1.0,
//         opacity,
//         ..Default::default()
//     }
// }
