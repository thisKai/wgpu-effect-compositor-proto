import package::util::system::px;
import package::util::anti_alias::edge_alpha;
import super::ray::{
    Ray,
    RayState,
    Ray_initial_state,
    Ray_position,
};
import super::scene::{scene_distance, SceneQuery_is_bg};
import super::shape::{
    MAX_DISTANCE,
    shape_normal,
    shape_anti_alias_distance,
};

fn raymarch(ray: Ray) -> RayMarch {
    var march = Ray_initial_state(ray);

    for (var i = 0; i < MAX_STEPS; i++) {
        march.position = Ray_position(ray, march.ray_distance);
        march.scene = scene_distance(march.position);
        march.ray_distance += march.scene.distance;

        if march.ray_distance > MAX_DISTANCE {
            return miss_distance(march);
        }
        if march.scene.distance < px(MIN_SURFACE_DISTANCE_PX) {
            return hit(march);
        }
    }

    return miss_steps(march);
}

const MIN_SURFACE_DISTANCE_PX = 1;
const MAX_STEPS = 256;

fn is_hit(result: RayMarch) -> bool {
    return result.result == HIT;
}
fn hit_alpha(result: RayMarch) -> f32 {
    let d = shape_anti_alias_distance(result.state.position.xy, result.state.scene.closest_shape_index);
    // let d = result.state.scene.distance;
    return edge_alpha(d);
}
fn hit_bg(result: RayMarch) -> bool {
    return SceneQuery_is_bg(result.state.scene);
}

fn hit(state: RayState) -> RayMarch {
    return RayMarch(HIT, state, shape_normal(state.position, state.scene.closest_shape_index));
}
fn miss_distance(state: RayState) -> RayMarch {
    return RayMarch(MISS_DISTANCE, state, vec3f(0, 0, 1));
}
fn miss_steps(state: RayState) -> RayMarch {
    return RayMarch(MISS_STEPS, state, vec3f(0, 0, 1));
}

const MISS_DISTANCE = 0;
const MISS_STEPS = 1;
const HIT = 2;

struct RayMarch {
    result: u32,
    state: RayState,
    normal: vec3f,
}
