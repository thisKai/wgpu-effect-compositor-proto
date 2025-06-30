import package::util::system::{px, px2_rh};

fn shape_count() -> u32 {
    return arrayLength(&shapes);
}
fn shape_kind(id: u32) -> u32 {
    return shapes[id].kind;
}

fn shape_location(id: u32) -> ShapeLocation {
    let map = shapes[id];
    let position = shape_position(id);
    return ShapeLocation(map, position);
}
struct ShapeLocation {
    map: ShapeEntry,
    position: ShapePosition,
}

fn shape_position(id: u32) -> ShapePosition {
    let position = &positions[id];
    let center = px2_rh(position.center);
    return ShapePosition(center);
}
fn shape_appearance(id: u32) -> ShapeAppearance {
    return appearances[id];
}

fn get_circle(circle_index: u32) -> Circle {
    return Circle(px(circles[circle_index].radius));
}

struct ShapeEntry {
    kind: u32,
    kind_index: u32,
}
struct ShapePosition {
    center: vec2f,
}
struct ShapeAppearance {
    tint_color: vec4f,
}

struct Circle {
    radius: f32,
}

@group(1) @binding(0) var<storage, read> shapes: array<ShapeEntry>;
@group(1) @binding(1) var<storage, read> positions: array<ShapePosition>;
@group(1) @binding(2) var<storage, read> appearances: array<ShapeAppearance>;

@group(1) @binding(3) var<storage, read> circles: array<Circle>;
