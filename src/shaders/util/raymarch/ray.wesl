import super::scene::{SceneQuery, SceneQuery_init};

struct Ray {
    origin: vec3f,
    direction: vec3f
}
fn Ray_initial_state(ray: Ray) -> RayState {
    let position = ray.origin;
    let ray_distance = 0.0;
    let steps = 0;
    let scene = SceneQuery_init();

    return RayState(position, ray_distance, steps, scene);
}
fn Ray_position(ray: Ray, ray_distance: f32) -> vec3f {
    return ray.origin + ray.direction * ray_distance;
}

struct RayState {
    position: vec3f,
    ray_distance: f32,
    steps: i32,
    scene: SceneQuery,
}
