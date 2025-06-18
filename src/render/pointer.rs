use std::mem;

pub struct PointerHit {
    pub index: usize,
    pub local_position: [f32; 2],
}

#[derive(Debug, Default)]
pub enum PointerState {
    #[default]
    Idle,
    Hovered {
        index: usize,
        hover_position: [f32; 2],
    },
    Pressed {
        index: usize,
        press_position: [f32; 2],
    },
    Dragging {
        index: usize,
        press_position: [f32; 2],
    },
}
impl PointerState {
    pub fn take(&mut self) -> Self {
        mem::take(self)
    }
}
