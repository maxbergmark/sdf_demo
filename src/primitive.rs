use crate::{pipeline::Pipeline, uniforms::Uniforms};

#[derive(Debug, Clone, Copy)]
pub struct Primitive {
    pub uniforms: Uniforms,
}

impl iced_wgpu::Primitive for Primitive {
    type Pipeline = Pipeline;

    fn prepare(
        &self,
        pipeline: &mut Self::Pipeline,
        _device: &wgpu::Device,
        queue: &wgpu::Queue,
        _bounds: &iced::Rectangle,
        _viewport: &iced_wgpu::graphics::Viewport,
    ) {
        queue.write_buffer(
            &pipeline.uniforms,
            0,
            bytemuck::bytes_of(&self.uniforms.to_raw()),
        );
    }

    fn draw(&self, pipeline: &Self::Pipeline, render_pass: &mut wgpu::RenderPass<'_>) -> bool {
        render_pass.set_pipeline(&pipeline.inner);
        render_pass.set_bind_group(0, &pipeline.uniform_bg, &[]);
        render_pass.draw(0..6, 0..1);
        true
    }
}
