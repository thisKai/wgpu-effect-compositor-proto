import super::ray::{Ray, ray};

fn ray_march_step(ray: ptr<function, Ray>, scene_distance: f32) {
    let state = &(*ray).state;
    state.distance += scene_distance;
    state.position = ray.origin + ray.direction * state.distance;
    state.steps++;
}

struct RayMarch {
    result: u32,
    ray: Ray,
    scene_distance: f32,
}

alias RayMarchResult = u32;
const RAYMARCH_MISSED_STEPS: RayMarchResult = 0;
const RAYMARCH_MISSED_DISTANCE: RayMarchResult = 1;
const RAYMARCH_HIT: RayMarchResult = 2;

const MAX_STEPS = 128;
const MAX_RAY_DISTANCE = 100.0;
const MIN_SURFACE_DISTANCE = 1e-3;
