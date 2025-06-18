@group(2) @binding(0) var<storage, read> shapes: array<Shape>;
@group(2) @binding(1) var<storage, read> spheres: array<Sphere>;

fn shape_count() -> u32 {
    return arrayLength(&shapes);
}

struct Shape {
    kind: u32,
    kind_index: u32,
}

const SHAPE_NONE = 0;
const SHAPE_SPHERE = 1;

const MAX_DISTANCE = 100.0;

fn shape_distance(p: vec3f, shape_index: u32) -> f32 {
    let shape = shapes[shape_index];
    switch shape.kind {
        case SHAPE_SPHERE {
            return sphere_distance(p, shape.kind_index);
        }
        default {
            return plane_distance(p, vec3f(0, 0, -1), 1);
        }
    }
}
fn shape_anti_alias_distance(p: vec2f, shape_index: u32) -> f32 {
    let shape = shapes[shape_index];
    switch shape.kind {
        case SHAPE_SPHERE {
            return sphere_anti_alias_distance(p, shape.kind_index);
        }
        default {
            return 0.0;
        }
    }
}
fn shape_normal(p: vec3f, shape_index: u32) -> vec3f {
    let distance = shape_distance(p, shape_index);
    let epsilon = vec2f(0.00001, 0);
    let n = distance - vec3f(
        shape_distance(p - epsilon.xyy, shape_index),
        shape_distance(p - epsilon.yxy, shape_index),
        shape_distance(p - epsilon.yyx, shape_index),
    );
    return normalize(n);
}

fn plane_distance(p: vec3f, n: vec3f, h: f32) -> f32 {
  // n must be normalized
    return dot(p, n) + h;
}

fn sphere_distance(p: vec3f, sphere_index: u32) -> f32 {
    let sphere = spheres[sphere_index];
    return distance(p, sphere.center) - sphere.radius;
}
fn sphere_anti_alias_distance(p: vec2f, sphere_index: u32) -> f32 {
    let sphere = spheres[sphere_index];
    return distance(p, sphere.center.xy) - sphere.radius;
}

struct Sphere {
    center: vec3f,
    radius: f32,
}
