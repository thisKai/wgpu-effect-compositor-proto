fn scene_distance(p: vec3f) -> f32 {
    var min_d = MAX_DISTANCE;

    for (var i: u32 = 0; i < 2; i++) {
        let shape_d = shape_distance(p, i);
        min_d = min(min_d, shape_d);
    }

    return min_d;
}
const MAX_DISTANCE = 100.0;

fn shape_distance(p: vec3f, shape_index: u32) -> f32 {
    let shape = get_shape(shape_index);
    switch shape.kind {
        case SHAPE_SPHERE {
            return sphere_distance(p, shape.kind_index);
        }
        default {
            return MAX_DISTANCE;
        }
    }
}
fn get_shape(index: u32) -> Shape {
    return SHAPES[index];
}

fn sphere_distance(p: vec3f, sphere_index: u32) -> f32 {
    let sphere = get_sphere(sphere_index);
    return distance(p, sphere.center) - sphere.radius;
}
fn get_sphere(index: u32) -> Sphere {
    return SPHERES[index];
}

struct SceneQuery {
    distance: f32,
    closest_shape: ShapeID,
}

const SHAPE_COUNT = 2;
const SHAPES = array<Shape, 2>(
    Shape(1, 0),
    Shape(1, 1),
);

struct ShapeID {
    index: u32,
}

const SHAPE_NONE = 1;
const SHAPE_SPHERE = 1;

struct Shape {
    kind: u32,
    kind_index: u32,
}

struct Sphere {
    center: vec3f,
    radius: f32,
}


const SPHERE_COUNT = 2;
const SPHERES = array<Sphere, 2>(
    Sphere(vec3f(-0.25, -0.25, 0), 0.25),
    Sphere(vec3f(0.25, 0.25, 0), 0.25),
);
