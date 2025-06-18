fn raymarch(ray: Ray) -> RayMarchResult {
    var march = Ray_begin_march(ray);

    for (var i = 0; i < MAX_STEPS; i++) {
        march.position = Ray_march_position(ray, march.ray_distance);
        march.scene_distance = scene_distance(march.position);
        march.ray_distance += march.scene_distance;

        if march.ray_distance > MAX_DISTANCE {
            return miss_distance(march);
        }
        if march.scene_distance < MIN_SURFACE_DISTANCE {
            return hit(march);
        }
    }

    return miss_steps(march);
}

const MIN_SURFACE_DISTANCE = 1e-3;
const MAX_DISTANCE = 100.0;
const MAX_STEPS = 256;

fn scene_distance(p: vec3f) -> f32 {
    return 1.0;
}

struct Ray {
    origin: vec3f,
    direction: vec3f
}
fn Ray_begin_march(ray: Ray) -> RayMarch {
    let position = ray.origin;
    let ray_distance = 0.0;
    let scene_distance = 0.0;
    let steps = 0;

    return RayMarch(position, ray_distance, scene_distance, steps);
}
fn Ray_march_position(ray: Ray, march: RayMarch) -> vec3f {
    return ray.origin + ray.direction * march.ray_distance;
}

fn hit(data: RayMarch) -> RayMarchResult {
    return RayMarchResult(HIT, data);
}
fn miss_distance(data: RayMarch) -> RayMarchResult {
    return RayMarchResult(MISS_DISTANCE, data);
}
fn miss_steps(data: RayMarch) -> RayMarchResult {
    return RayMarchResult(MISS_STEPS, data);
}

const MISS_DISTANCE = 0;
const MISS_STEPS = 1;
const HIT = 2;

struct RayMarchResult {
    kind: u32,
    data: RayMarch,
}

struct RayMarch {
    position: vec3f,
    ray_distance: f32,
    scene_distance: f32,
    steps: i32,
}

struct MarchOptions {
    inside: bool,
}
