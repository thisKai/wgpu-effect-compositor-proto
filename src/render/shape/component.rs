#[allow(non_camel_case_types)]
pub type vec2f = [f32; 2];

#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(transparent)]
pub struct RGBA([f32; 4]);

impl From<u32> for RGBA {
    fn from(value: u32) -> Self {
        let rgba = value.to_be_bytes();
        RGBA(rgba.map(|c| c as f32 / 255.0))
    }
}

#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(transparent)]
pub struct ShapeId(u32);
impl From<u32> for ShapeId {
    fn from(value: u32) -> Self {
        Self(value)
    }
}
EnumShaderConstants!(
    pub enum ShapeKind {
        Circle = 1,
    }
);

#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(transparent)]
pub struct ShapeKindIndex(u32);
impl From<u32> for ShapeKindIndex {
    fn from(value: u32) -> Self {
        Self(value)
    }
}
