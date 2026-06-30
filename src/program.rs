use crate::{primitive::Primitive, uniforms::Uniforms};

#[derive(Debug, Clone, Copy)]
pub struct Program {
    pub uniforms: Uniforms,
}

impl iced::widget::shader::Program<crate::Message> for Program {
    type State = ();

    type Primitive = Primitive;

    fn draw(
        &self,
        _state: &Self::State,
        _cursor: iced::advanced::mouse::Cursor,
        _bounds: iced::Rectangle,
    ) -> Self::Primitive {
        Primitive {
            uniforms: self.uniforms,
        }
    }
}
