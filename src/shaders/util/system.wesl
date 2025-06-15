@group(0) @binding(0)
var<uniform> viewport: Viewport;
@group(0) @binding(1)
var<uniform> cursor: Cursor;

struct Viewport {
    size: vec2f,
}
fn cover_ratio() -> vec2f {
    let max_dimension = max(viewport.size.x, viewport.size.y);
    return viewport.size / max_dimension;
}

struct Cursor {
    position: vec2f,
}
