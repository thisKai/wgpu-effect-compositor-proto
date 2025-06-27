use std::{array, mem};

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

pub trait BoundingBox {
    fn bounding_box(&self) -> AABB;
}
pub struct AABB {
    pub min: [f32; 2],
    pub max: [f32; 2],
}
impl AABB {
    pub fn local_point(&self, x: f32, y: f32) -> [f32; 2] {
        let [left, top] = self.min;
        let local_x = x - left;
        let local_y = y - top;
        [local_x, local_y]
    }
    pub fn hit_test(&self, x: f32, y: f32) -> bool {
        let &Self {
            min: [min_x, min_y],
            max: [max_x, max_y],
        } = self;
        (min_x..max_x).contains(&x) && (min_y..max_y).contains(&y)
    }
    pub fn with_center(&self, center: [f32; 2]) -> Self {
        Self {
            min: array::from_fn(|i| self.min[i] + center[i]),
            max: array::from_fn(|i| self.max[i] + center[i]),
        }
    }
}
