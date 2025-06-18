import super::ray::{
    Ray,
    RayState,
    Ray_initial_state,
    Ray_position,
};
import super::scene::scene_distance;
import super::shape::MAX_DISTANCE;

fn raymarch(ray: Ray) -> RayMarch {
    var march = Ray_initial_state(ray);

    for (var i = 0; i < MAX_STEPS; i++) {
        march.position = Ray_position(ray, march.ray_distance);
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
const MAX_STEPS = 256;

fn is_hit(result: RayMarch) -> bool {
    return result.result == HIT;
}
fn hit_alpha(result: RayMarch) -> f32 {
    let d = result.state.scene_distance;
    return smoothstep(MIN_SURFACE_DISTANCE, -0.003, d - MIN_SURFACE_DISTANCE);
}

fn hit(state: RayState) -> RayMarch {
    return RayMarch(HIT, state);
}
fn miss_distance(state: RayState) -> RayMarch {
    return RayMarch(MISS_DISTANCE, state);
}
fn miss_steps(state: RayState) -> RayMarch {
    return RayMarch(MISS_STEPS, state);
}

const MISS_DISTANCE = 0;
const MISS_STEPS = 1;
const HIT = 2;

struct RayMarch {
    result: u32,
    state: RayState,
}
