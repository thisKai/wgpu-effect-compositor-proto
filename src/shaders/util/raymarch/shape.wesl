import package::util::system::{px, px2, px3, viewport};
import package::util::norm::{p_norm_length2, p_norm_length3};

@group(2) @binding(0) var<storage, read> shapes: array<Shape>;
@group(2) @binding(1) var<storage, read> spheres: array<Sphere>;
@group(2) @binding(2) var<storage, read> rounded_boxes: array<RoundedBox>;

fn shape_count() -> u32 {
    return arrayLength(&shapes);
}

struct Shape {
    kind: u32,
    kind_index: u32,
}

const SHAPE_NONE = 0;
const SHAPE_SPHERE = 1;
const SHAPE_ROUNDED_BOX = 2;

const MAX_DISTANCE = 100.0;

fn shape_distance(p: vec3f, shape_index: u32) -> f32 {
    let shape = shapes[shape_index];
    switch shape.kind {
        case SHAPE_SPHERE {
            return sphere_distance(p, shape.kind_index);
        }
        case SHAPE_ROUNDED_BOX {
            return rounded_box_distance(p, shape.kind_index);
        }
        default {
            return plane_distance(p, vec3f(0, 0, -1), 1);
        }
    }
}
fn shape_silhouette_distance(p: vec2f, shape_index: u32) -> f32 {
    let shape = shapes[shape_index];
    switch shape.kind {
        case SHAPE_SPHERE {
            return sphere_silhouette_distance(p, shape.kind_index);
        }
        case SHAPE_ROUNDED_BOX {
            return rounded_box_silhouette_distance(p, shape.kind_index);
        }
        default {
            return 0.0;
        }
    }
}
fn shape_normal0(p: vec3f, shape_index: u32, inside: f32) -> vec3f {
    let distance = shape_distance(p, shape_index) * inside;
    let epsilon = vec2f(0.0001, 0);
    let n = distance - vec3f(
        shape_distance(p - epsilon.xyy, shape_index) * inside,
        shape_distance(p - epsilon.yxy, shape_index) * inside,
        shape_distance(p - epsilon.yyx, shape_index) * inside,
    );
    return normalize(n);
}

fn shape_normal(p: vec3f, shape_index: u32, inside: f32) -> vec3f {
    let h = 1e-3;
    let k = vec2f(1, -1);
    return normalize(k.xyy * shape_distance(p + k.xyy * h, shape_index) + k.yyx * shape_distance(p + k.yyx * h, shape_index) + k.yxy * shape_distance(p + k.yxy * h, shape_index) + k.xxx * shape_distance(p + k.xxx * h, shape_index));
}

fn plane_distance(p: vec3f, n: vec3f, h: f32) -> f32 {
  // n must be normalized
    return dot(p, n) + h;
}

fn sphere_distance(p: vec3f, sphere_index: u32) -> f32 {
    let sphere = spheres[sphere_index];
    let xy = px2(sphere.center.xy - (viewport.size / 2));
    let z = 1 - px(sphere.center.z);

    let xy_d = length(p.xy - xy);
    let z_d = p.z - z;

    let d = p_norm_length2(vec2f(xy_d, z_d), 4);
    return d - px(sphere.radius);
}
fn sphere_distance0(p: vec3f, sphere_index: u32) -> f32 {
    let sphere = spheres[sphere_index];
    return distance(p, vec3f(px2(sphere.center.xy - (viewport.size / 2)), 1 - px(sphere.center.z))) - px(sphere.radius);
}
fn sphere_silhouette_distance(p: vec2f, sphere_index: u32) -> f32 {
    let sphere = spheres[sphere_index];
    return distance(p, px2(sphere.center.xy - (viewport.size / 2))) - px(sphere.radius);
}

struct Sphere {
    center: vec3f,
    radius: f32,
}

fn rounded_box_distance(p: vec3f, rounded_box_index: u32) -> f32 {
    let rounded_box = rounded_boxes[rounded_box_index];
    let box = rounded_cuboid_sd(p - vec3f(px2(rounded_box.center.xy - (viewport.size / 2)), 1 - px(rounded_box.center.z)), px3(rounded_box.half_size), px(rounded_box.radius));
    return box;
}
fn rounded_box_silhouette_distance(p: vec2f, rounded_box_index: u32) -> f32 {
    let rounded_box = rounded_boxes[rounded_box_index];
    return rounded_rect_sd(p - px2(rounded_box.center.xy - (viewport.size / 2)), px2(rounded_box.half_size.xy), px(rounded_box.radius));
}

fn rounded_cuboid_sd(p: vec3f, b: vec3f, radius: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    return p_norm_cuboid_sd(p, b - r, 4) - r;
}
fn cuboid_sd(p: vec3f, b: vec3f) -> f32 {
    let q = abs(p) - b;
    return length(max(q, vec3f(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}
fn rounded_rect_sd(p: vec2f, b: vec2f, radius: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    return p_norm_rect_sd(p, b - r, 4) - r;
}
fn rect_sd(p: vec2f, b: vec2f) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

fn p_norm_cuboid_sd(p: vec3f, b: vec3f, e: f32) -> f32 {
    let q = abs(p) - b;
    return p_norm_length3(max(q, vec3f(0.0)), e) + min(max(q.x, max(q.y, q.z)), 0.0);
}
fn p_norm_rect_sd(p: vec2f, b: vec2f, e: f32) -> f32 {
    let d = abs(p) - b;
    return p_norm_length2(max(d, vec2(0.0)), e) + min(max(d.x, d.y), 0.0);
}

struct RoundedBox {
    center: vec3f,
    half_size: vec3f,
    radius: f32,
}
