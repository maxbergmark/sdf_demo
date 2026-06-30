use std::sync::LazyLock;

use iced::widget::svg;
use iced::{Element, Length};
use typst::foundations::{Dict, IntoValue};
use typst::layout::{Abs, PagedDocument};
use typst_as_lib::TypstEngine;
use typst_as_lib::TypstTemplateMainFile;
use typst_as_lib::typst_kit_options::TypstKitFontOptions;

/// Typst template that turns the injected `equation` string into white display math
/// on a transparent, auto-sized page so it composites cleanly over the shader.
static TEMPLATE: &str = r#"#import sys: inputs
#set page(width: auto, height: auto, margin: 0.4em, fill: none)
#set text(fill: white, size: 24pt)
$ #eval(inputs.equation, mode: "math") $
"#;

/// Built once: searching/loading fonts is the expensive part, so we keep the engine
/// (with embedded math-capable fonts) alive for the lifetime of the app.
static ENGINE: LazyLock<TypstEngine<TypstTemplateMainFile>> = LazyLock::new(|| {
    TypstEngine::builder()
        .main_file(TEMPLATE)
        .search_fonts_with(
            TypstKitFontOptions::default()
                .include_system_fonts(false)
                .include_embedded_fonts(true),
        )
        .build()
});

fn render_svg(equation: &str) -> Option<String> {
    let mut inputs = Dict::new();
    inputs.insert("equation".into(), equation.into_value());

    let result = ENGINE.compile_with_input::<_, PagedDocument>(inputs);
    let doc = match result.output {
        Ok(doc) => doc,
        Err(err) => {
            tracing::warn!("typst compile failed for `{equation}`: {err}");
            return None;
        }
    };

    Some(typst_svg::svg_merged(&doc, Abs::zero()))
}

pub fn equation_view<'a, M: 'static + Clone>(equation: &str, opacity: f32) -> Element<'a, M> {
    let Some(svg_string) = render_svg(equation) else {
        return iced::widget::space().into();
    };

    let handle = svg::Handle::from_memory(svg_string.into_bytes());
    svg(handle)
        .opacity(opacity)
        .width(Length::Shrink)
        .height(Length::Shrink)
        .into()
}
