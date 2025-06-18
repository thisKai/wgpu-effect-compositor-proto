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
            return MAX_DISTANCE;
        }
    }
}

fn sphere_distance(p: vec3f, sphere_index: u32) -> f32 {
    let sphere = spheres[sphere_index];
    return distance(p, sphere.center) - sphere.radius;
}

struct Sphere {
    center: vec3f,
    radius: f32,
}
