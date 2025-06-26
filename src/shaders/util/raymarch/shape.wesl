import package::util::system::{px, px2, px3, viewport};
import package::util::norm::{p_norm_length2, p_norm_length3};
import package::shape::sdf::lpm_norm::superformula_sd;
import package::shape::sdf::extrude::extrude_p;

@group(2) @binding(0) var<storage, read> shapes: array<Shape>;
@group(2) @binding(1) var<storage, read> spheres: array<Sphere>;
@group(2) @binding(2) var<storage, read> rounded_boxes: array<RoundedBox>;
@group(2) @binding(3) var<storage, read> superformulas: array<SuperformulaRaw>;


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
const SHAPE_SUPERFORMULA = 3;

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
        // case SHAPE_SUPERFORMULA {
        //     return superformula_distance(p, shape.kind_index);
        // }
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
        // case SHAPE_SUPERFORMULA {
        //     return superformula_silhouette_distance(p, shape.kind_index);
        // }
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
    let h = px(1);
    let k = vec2f(1, -1);
    return normalize(k.xyy * shape_distance(p + k.xyy * h, shape_index) + k.yyx * shape_distance(p + k.yyx * h, shape_index) + k.yxy * shape_distance(p + k.yxy * h, shape_index) + k.xxx * shape_distance(p + k.xxx * h, shape_index));
}

fn plane_distance(p: vec3f, n: vec3f, h: f32) -> f32 {
  // n must be normalized
    return dot(p, n) + h;
}
fn plane_intersect_distance(ro: vec3f, rd: vec3f, p: vec4f) -> f32 {
    // plane degined by p (p.xyz must be normalized)
    return -(dot(ro, p.xyz) + p.w) / dot(rd, p.xyz);
}

fn capsule_sd(p: vec3f, a: vec3f, b: vec3f, r: f32) -> f32 {
    let pa = p - a;
    let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
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

struct SuperformulaRaw {
    data: array<f32,9>,
}
fn superformula_distance(p: vec3f, superformula_index: u32) -> f32 {
    let superformula = Superformula_from_raw(superformulas[superformula_index]);

    let xy = px2(superformula.center.xy - (viewport.size / 2));
    let z = 1 - px(superformula.center.z);

    let p_t = p - vec3f(xy, z);
    let d2 = superformula_sd(p_t.xy, superformula.sides, px2(superformula.radii), superformula.exponents);

    return extrude_p(d2, p_t.z, px(64), 4) - px(64);
}
fn superformula_silhouette_distance(p: vec2f, superformula_index: u32) -> f32 {
    let superformula = Superformula_from_raw(superformulas[superformula_index]);

    let center = px2(superformula.center.xy - (viewport.size / 2));

    let p_t = p - center;
    return superformula_sd(p_t.xy, superformula.sides, px2(superformula.radii), superformula.exponents) - px(64);
}

struct Superformula {
    center: vec3f,
    sides: f32,
    radii: vec2f,
    exponents: vec3f,
}
fn Superformula_from_raw(raw: SuperformulaRaw) -> Superformula {
    let data = raw.data;
    let center = vec3f(data[0], data[1], data[2]);
    let sides = data[3];
    let radii = vec2f(data[4], data[5]);
    let exponents = vec3f(data[6], data[7], data[8]);
    return Superformula(center, sides, radii, exponents);
}
