use iced::time::Instant;
use iced::{Background, Font, Radians, Rotation};

use iced::widget::svg;
use iced::{
    Alignment, Animation, Border, Color, Element, Length, Padding, Size, Subscription, Task,
    keyboard::key::Named,
    mouse::Interaction,
    widget::{button, column, container, mouse_area, responsive, row, space, stack, text},
};

use iced_glass::widget::container as glass_container;

use crate::slides::Slide;
use crate::{
    code::{Language, code_view},
    program::Program,
    slides::SLIDES,
    uniforms::Uniforms,
};

#[cfg(not(target_arch = "wasm32"))]
use crate::equation::equation_view;

mod code;
#[cfg(not(target_arch = "wasm32"))]
mod equation;
mod pipeline;
mod primitive;
mod program;
mod slides;
mod uniforms;

#[derive(Debug)]
pub struct Ui {
    uniforms: Uniforms,
    blend: Animation<f32>,
    rendering_blend: Animation<f32>,
    a: Animation<f32>,
    // slides: Vec<Slide>,
    index: usize,
    current_shape: u32,
    start_time: Instant,
    info: bool,
}

#[allow(unused)]
#[derive(Debug, Clone, Copy)]
pub enum Message {
    Next,
    Previous,
    MouseMoved(iced::Point),
    ShowDistance(bool),
    RenderingMethod(RenderingMethod),
    ToggleInfo,
    OpenUrl(&'static str),
    // Blend(f32),
    // A(f32),
    // B(f32),
    // C(f32),
    None,
    Tick,
}

#[derive(Debug, Clone, Copy)]
pub enum RenderingMethod {
    Distance = 0,
    Gradient = 1,
    Outline = 2,
    Fill = 3,
    Shadow = 4,
    Core = 5,
    Glow = 6,
}

fn main() -> iced::Result {
    #[cfg(target_arch = "wasm32")]
    {
        console_error_panic_hook::set_once();
        let _ = console_log::init_with_level(log::Level::Warn);
    }

    // tracing_subscriber::fmt()
    //     .pretty() // multi-line, color-coded output with file:line info
    //     .with_env_filter("warn,iced=warn")
    //     .init();

    iced::application(Ui::boot, Ui::update, Ui::view)
        .font(include_bytes!("../fonts/roboto.ttf"))
        .font(notosans::REGULAR_TTF)
        .subscription(Ui::subscription)
        .antialiasing(true)
        .window_size(Size::new(2560.0, 1440.0))
        .title("SDF Demo")
        .run()
}

impl Default for Ui {
    fn default() -> Self {
        Self {
            // width: 1440.0,
            // height: 1440.0,
            uniforms: Uniforms {
                from: 0,
                to: 0,
                rendering_method_from: RenderingMethod::Fill as u32,
                rendering_method_to: RenderingMethod::Fill as u32,
                blend: 0.0,
                a: SLIDES[0].a,
                ..Default::default()
            },
            blend: Animation::new(0.0).slow(),
            rendering_blend: Animation::new(0.0).slow(),
            a: Animation::new(0.0).slow(),
            // slides: slides::SLIDES.to_vec(),
            index: 0,
            current_shape: 0,
            start_time: Instant::now(),
            info: false,
        }
    }
}

impl Ui {
    pub fn boot() -> (Ui, Task<Message>) {
        (Self::default(), Task::none())
    }

    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::Next => {
                let now = Instant::now();
                self.index = (self.index + 1) % SLIDES.len();
                self.blend = Animation::new(0.0).slow();
                self.blend.go_mut(1.0, now);
                self.a.go_mut(SLIDES[self.index].a, now);
                self.uniforms.from = self.current_shape;
                self.uniforms.to = SLIDES[self.index].shape;
                self.uniforms.blend = 0.0;
                self.current_shape = SLIDES[self.index].shape;
                if SLIDES[self.index].rendering_method.is_some() {
                    self.uniforms.rendering_method_from = self.uniforms.rendering_method_to;
                    self.uniforms.rendering_method_to =
                        SLIDES[self.index].rendering_method.unwrap() as u32;
                    self.rendering_blend = Animation::new(0.0).slow();
                    self.rendering_blend.go_mut(1.0, now);
                    self.uniforms.rendering_blend = 0.0;
                }

                self.uniforms.last_frame_start = self.uniforms.frame_start;
                self.uniforms.frame_start = self.start_time.elapsed().as_secs_f32();
            }
            Message::Previous => {
                self.index = (self.index + SLIDES.len() - 1) % SLIDES.len();
                let now = Instant::now();
                self.blend = Animation::new(0.0).slow();
                self.blend.go_mut(1.0, now);
                self.a.go_mut(SLIDES[self.index].a, now);
                self.uniforms.from = self.current_shape;
                self.uniforms.to = SLIDES[self.index].shape;
                self.uniforms.blend = 0.0;
                self.current_shape = SLIDES[self.index].shape;

                self.uniforms.last_frame_start = self.uniforms.frame_start;
                self.uniforms.frame_start = self.start_time.elapsed().as_secs_f32();
            }
            Message::MouseMoved(mouse) => {
                self.uniforms.mouse = mouse;
            }
            Message::ShowDistance(show) => {
                self.uniforms.show_distance = show;
            }
            Message::OpenUrl(url) => {
                #[cfg(not(target_arch = "wasm32"))]
                {
                    let _ = open::that(url);
                }
                #[cfg(target_arch = "wasm32")]
                if let Some(win) = web_sys::window() {
                    let _ = win.open_with_url_and_target(url, "_blank");
                }
            }
            Message::ToggleInfo => {
                self.info = !self.info;
            }
            Message::Tick => {
                let now = Instant::now();
                self.uniforms.blend = self.blend.interpolate_with(|t| t, now);
                self.uniforms.rendering_blend = self.rendering_blend.interpolate_with(|t| t, now);
                self.uniforms.a = self.a.interpolate_with(|t| t, now);
                self.uniforms.t = self.start_time.elapsed().as_secs_f32();
            }
            Message::RenderingMethod(method) => {
                let now = Instant::now();
                self.uniforms.rendering_method_from = self.uniforms.rendering_method_to;
                self.uniforms.rendering_method_to = method as u32;
                self.rendering_blend = Animation::new(0.0).slow();
                self.rendering_blend.go_mut(1.0, now);
                self.uniforms.rendering_blend = 0.0;
            }
            Message::None => (),
        }
        Task::none()
    }

    pub fn subscription(&self) -> Subscription<Message> {
        let timer = iced::time::every(std::time::Duration::from_millis(10)).map(|_| Message::Tick);
        let _transition =
            iced::time::every(std::time::Duration::from_millis(1000)).map(|_| Message::Next);
        let keyboard = iced::keyboard::listen().filter_map(|event| match event {
            iced::keyboard::Event::KeyPressed { key, .. } => match key {
                iced::keyboard::Key::Named(Named::ArrowRight) => Some(Message::Next),
                iced::keyboard::Key::Named(Named::ArrowLeft) => Some(Message::Previous),
                iced::keyboard::Key::Character(c) => match c.chars().next().unwrap() {
                    '1' => Some(Message::RenderingMethod(RenderingMethod::Distance)),
                    '2' => Some(Message::RenderingMethod(RenderingMethod::Gradient)),
                    '3' => Some(Message::RenderingMethod(RenderingMethod::Outline)),
                    '4' => Some(Message::RenderingMethod(RenderingMethod::Fill)),
                    '5' => Some(Message::RenderingMethod(RenderingMethod::Shadow)),
                    '6' => Some(Message::RenderingMethod(RenderingMethod::Core)),
                    '7' => Some(Message::RenderingMethod(RenderingMethod::Glow)),
                    _ => None,
                },
                _ => None,
            },
            _ => None,
        });
        Subscription::batch(vec![timer, /*transition, */ keyboard])
    }

    pub fn view(&self) -> Element<'_, Message> {
        responsive(move |size| {
            mouse_area(stack![
                iced::widget::shader(Program {
                    uniforms: self.uniforms.with_size(size.width, size.height)
                })
                .width(size.width)
                .height(size.height),
                self.overlay(),
                self.slide_overlay(),
            ])
            .on_move(move |mouse| {
                let aspect_ratio = size.width / size.height;
                Message::MouseMoved(iced::Point::new(
                    (mouse.x / size.width * 2.0 - 1.0) * aspect_ratio,
                    mouse.y / size.height * 2.0 - 1.0,
                ))
            })
            .on_press(Message::ShowDistance(true))
            .on_release(Message::ShowDistance(false))
            .interaction(if self.index == SLIDES.len() - 1 {
                Interaction::Idle
                // Interaction::Pointer
            } else {
                Interaction::Hidden
            })
        })
        .into()
    }

    pub fn overlay(&self) -> Element<'_, Message> {
        let slide = &SLIDES[self.index];
        self.transition_opacity(move |opacity| {
            container(
                column![
                    glass_container(
                        row![
                            container(slide.code.map(move |code| code_view(
                                code,
                                opacity,
                                Language::Wgsl
                            )))
                            .align_x(Alignment::Start)
                            .width(Length::Fill)
                            .center_y(Length::Fill),
                            self.equation(slide, opacity),
                        ]
                        .spacing(10.0)
                    )
                    .glass_style(move |_theme| iced_glass::Style {
                        blur_radius: 10.0,
                        saturation: 1.0,
                        lightness: -2.5,
                        edge_radius: 20.0,
                        edge_height: 200.0,
                        rim_angle: 1.0,
                        opacity,
                        ..Default::default()
                    })
                    .style(|_theme| container::Style {
                        border: Border::default().rounded(40.0),
                        ..Default::default()
                    })
                    .width(1000.0)
                    .height(220.0)
                    .padding(Padding::new(30.0).horizontal(40.0)),
                    container(self.info_overlay())
                        .align_bottom(Length::Fill)
                        .align_left(Length::Fill),
                    container(row![
                        row![
                            info_button(),
                            navigation_button(Message::Previous),
                            navigation_button(Message::Next),
                        ]
                        .spacing(20.0),
                        space().width(Length::Fill),
                        row![
                            glass_button("Distance", RenderingMethod::Distance),
                            glass_button("Gradient", RenderingMethod::Gradient),
                            glass_button("Outline", RenderingMethod::Outline),
                            glass_button("Fill", RenderingMethod::Fill),
                            glass_button("Shadow", RenderingMethod::Shadow),
                            glass_button("Core", RenderingMethod::Core),
                            glass_button("Glow", RenderingMethod::Glow),
                        ]
                        .spacing(20.0)
                    ])
                    .align_bottom(80.0)
                    .align_right(Length::Fill)
                ]
                .width(Length::Fill)
                .align_x(Alignment::Center),
            )
            .center_x(Length::Fill)
            .height(Length::Fill)
            .padding(Padding::new(20.0))
        })
    }

    fn info_overlay(&self) -> Element<'_, Message> {
        self.info_opacity(move |opacity| {
            glass_container(column![
                text("Controls").size(20.0).font(FONT_NOTO).color(Color::from_rgba(1.0, 1.0, 1.0, opacity)),
                row![
                    text("← →\n\n1-7\n\n\n\n\n\n\n\n\nLeft Click + Drag")
                        .size(15.0).font(FONT_NOTO)
                        .align_x(Alignment::End)
                        .color(Color::from_rgba(1.0, 1.0, 1.0, opacity)),
                    container(space())
                        .width(1.0).height(Length::Fill)
                        .style(move |_theme| container::Style {
                            background: Some(Background::Color(Color::from_rgba(1.0, 1.0, 1.0, 0.3 * opacity))),
                    ..Default::default()
                }),
                text(
                    "Previous / Next slide\n\nRendering mode: \n    1 Distance\n    2 Gradient\n    3 Outline\n    4 Fill\n    5 Shadow\n    6 Core\n    7 Glow\n\nVisualize the distance field"
                )
                .size(15.0)
                .font(FONT_NOTO)
                .color(Color::from_rgba(1.0, 1.0, 1.0, opacity))].spacing(10.0)
            ])
            .glass_style(move |_theme| iced_glass::Style {
                blur_radius: 10.0,
                saturation: 1.0,
                lightness: -2.5,
                edge_radius: 20.0,
                edge_height: 200.0,
                rim_angle: 1.0,
                opacity,
                ..Default::default()
            })
            .style(|_theme| container::Style {
                border: Border::default().rounded(40.0),
                ..Default::default()
            })
            .padding(40.0)
        })
    }

    fn slide_overlay(&self) -> Element<'_, Message> {
        let slide = &SLIDES[self.index];
        let blend = self.uniforms.blend;
        let t = self.uniforms.t;
        container(slide.overlay.unwrap_or(|_, _| space().into())(blend, t))
            .center(Length::Fill)
            .into()
    }

    #[cfg(not(target_arch = "wasm32"))]
    fn equation(&self, slide: &Slide, opacity: f32) -> Element<'_, Message> {
        container(
            slide
                .equation
                .map(move |equation| equation_view(equation, opacity)),
        )
        .align_x(Alignment::End)
        .center_y(Length::Fill)
        .into()
    }

    #[cfg(target_arch = "wasm32")]
    fn equation(&self, _slide: &Slide, _opacity: f32) -> Element<'_, Message> {
        space().into()
    }

    fn transition_opacity<'a, F, T>(&self, f: F) -> Element<'a, Message>
    where
        F: Fn(f32) -> T + 'a,
        T: Into<Element<'a, Message>>,
    {
        let slide = &SLIDES[self.index];
        let opacity = slide.code.map(|_| 1.0).unwrap_or_default();
        iced::widget::transition(
            opacity,
            || {
                Animation::new(0.0)
                    .slow()
                    .easing(iced::animation::Easing::EaseInOutCubic)
            },
            move |animation, now| f(animation.interpolate_with(std::convert::identity, now)),
        )
        .into()
    }

    fn info_opacity<'a, F, T>(&self, f: F) -> Element<'a, Message>
    where
        F: Fn(f32) -> T + 'a,
        T: Into<Element<'a, Message>>,
    {
        let opacity = if self.info { 1.0 } else { 0.0 };
        iced::widget::transition(
            opacity,
            || {
                Animation::new(0.0)
                    .slow()
                    .easing(iced::animation::Easing::EaseInOutCubic)
            },
            move |animation, now| f(animation.interpolate_with(std::convert::identity, now)),
        )
        .into()
    }
}

const FONT_NOTO: Font = Font {
    family: iced::font::Family::Name("Noto Sans"),
    weight: iced::font::Weight::Normal,
    stretch: iced::font::Stretch::Normal,
    style: iced::font::Style::Normal,
};

fn info_button() -> Element<'static, Message> {
    glass_container(
        button(text("?").size(20.0).font(FONT_NOTO))
            .style(button_style)
            .on_press(Message::ToggleInfo),
    )
    .glass_style(|_theme| iced_glass::Style {
        blur_radius: 10.0,
        saturation: 1.0,
        lightness: -2.5,
        edge_radius: 20.0,
        edge_height: 200.0,
        rim_angle: 1.0,
        ..Default::default()
    })
    .style(|_theme| container::Style {
        border: Border::default().rounded(25.0),
        ..Default::default()
    })
    .center_x(50.0)
    .center_y(50.0)
    .padding(5.0)
    .into()
}

fn glass_button(s: &str, method: RenderingMethod) -> Element<'_, Message> {
    glass_container(
        button(text(s).size(15.0).font(FONT_NOTO))
            .style(button_style)
            .on_press(Message::RenderingMethod(method)),
    )
    .glass_style(|_theme| iced_glass::Style {
        blur_radius: 10.0,
        saturation: 1.0,
        lightness: -2.5,
        edge_radius: 20.0,
        edge_height: 200.0,
        rim_angle: 1.0,
        ..Default::default()
    })
    .style(|_theme| container::Style {
        border: Border::default().rounded(5.0),
        ..Default::default()
    })
    .center_x(80.0)
    .center_y(30.0)
    .padding(0.0)
    .into()
}

fn navigation_button(message: Message) -> Element<'static, Message> {
    let rotation = match message {
        Message::Previous => Radians::PI,
        Message::Next => Radians(0.0),
        _ => Radians(0.0),
    };
    glass_container(
        button(
            svg(svg::Handle::from_memory(include_bytes!(
                "../assets/play.svg"
            )))
            .rotation(Rotation::Solid(rotation))
            .style(|_, _| svg::Style {
                color: Some(Color::WHITE),
            })
            .opacity(0.5)
            .width(Length::Fill)
            .height(Length::Fill),
        )
        .style(button_style)
        .on_press(message),
    )
    .glass_style(|_theme| iced_glass::Style {
        blur_radius: 10.0,
        saturation: 1.0,
        lightness: -2.5,
        edge_radius: 20.0,
        edge_height: 200.0,
        rim_angle: 1.0,
        ..Default::default()
    })
    .style(|_theme| container::Style {
        border: Border::default().rounded(25.0),
        ..Default::default()
    })
    .center_x(50.0)
    .center_y(50.0)
    .padding(5.0)
    .into()
}

fn button_style(_theme: &iced::Theme, _status: button::Status) -> button::Style {
    button::Style {
        background: None,
        text_color: Color::from_rgba(1.0, 1.0, 1.0, 0.5),
        ..Default::default()
    }
}
