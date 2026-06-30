#[derive(Debug, Default, Clone, Copy)]
pub struct Uniforms {
    pub mouse: iced::Point,
    pub show_distance: bool,
    pub width: f32,
    pub height: f32,
    pub from: u32,
    pub to: u32,
    pub blend: f32,
    pub a: f32,
    pub rendering_method_from: u32,
    pub rendering_method_to: u32,
    pub rendering_blend: f32,
    pub t: f32,
    pub frame_start: f32,
    pub last_frame_start: f32,
}

impl Uniforms {
    #[must_use]
    pub fn to_raw(self) -> Raw {
        Raw {
            mouse: [self.mouse.x, self.mouse.y],
            width: self.width,
            height: self.height,
            from: self.from,
            to: self.to,
            blend: self.blend,
            a: self.a,
            rendering_method_from: self.rendering_method_from,
            rendering_method_to: self.rendering_method_to,
            rendering_blend: self.rendering_blend,
            t: self.t,
            frame_start: self.frame_start,
            last_frame_start: self.last_frame_start,
            show_distance: self.show_distance as u32,
            _pad: 0.0,
        }
    }

    pub fn with_size(self, width: f32, height: f32) -> Self {
        Self {
            width,
            height,
            ..self
        }
    }
}

#[derive(Debug, Default, Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(C)]
pub struct Raw {
    pub mouse: [f32; 2],
    pub width: f32,
    pub height: f32,
    pub from: u32,
    pub to: u32,
    pub blend: f32,
    pub a: f32,
    pub rendering_method_from: u32,
    pub rendering_method_to: u32,
    pub rendering_blend: f32,
    pub t: f32,
    pub frame_start: f32,
    pub last_frame_start: f32,
    pub show_distance: u32,
    pub _pad: f32,
}
