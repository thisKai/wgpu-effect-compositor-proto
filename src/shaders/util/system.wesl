import super::quad_vertex::{cover_ratio, fit_ratio};

@group(0) @binding(0)
var<uniform> viewport: Viewport;
@group(0) @binding(1)
var<uniform> cursor: Cursor;

struct Viewport {
    size: vec2f,
    size_uv: vec2f,
    px: f32,
}
fn px(scalar: f32) -> f32 {
    return scalar * viewport.px;
}
fn px2(vector2: vec2f) -> vec2f {
    return vector2 * viewport.px;
}
fn px3(vector3: vec3f) -> vec3f {
    return vector3 * viewport.px;
}
fn px23(vector3: vec3f) -> vec3f {
    return vector3 * viewport.px;
}

fn px2_rh(vector2: vec2f) -> vec2f {
    return px2(vector2 - (viewport.size / 2));
}

fn viewport_fit_ratio() -> vec2f {
    return fit_ratio(viewport.size);
}
fn viewport_cover_ratio() -> vec2f {
    return cover_ratio(viewport.size);
}

struct Cursor {
    position: vec2f,
}
