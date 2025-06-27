fn ray(origin: vec3f, direction: vec3f) -> Ray {
    return Ray(origin, direction, ray_initial_state(origin));
}
fn frag_ray_down(p: vec2f) -> Ray {
    return ray(vec3f(p, 0), vec3f(0, 0, 1));
}
fn ray_incident(ray: Ray) -> vec3f {
    return normalize(ray.state.position - ray.origin);
}

struct Ray {
    origin: vec3f,
    direction: vec3f,
    state: RayState,
}

fn ray_initial_state(origin: vec3f) -> RayState {
    return RayState(origin, 0, 0);
}
struct RayState {
    position: vec3f,
    distance: f32,
    steps: i32,
}
