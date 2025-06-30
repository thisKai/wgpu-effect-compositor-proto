fn ray(origin: vec3f, direction: vec3f) -> Ray {
    return Ray(origin, direction, ray_initial_state(origin));
}
fn frag_ray_down(p: vec2f) -> Ray {
    return ray(vec3f(p, 0), vec3f(0, 0, 1));
}
fn ray_incident(ray: Ray) -> vec3f {
    return normalize(ray.state.position - ray.origin);
}
fn frag_ray_incident(p: vec2f, z: f32) -> vec3f {
    return normalize(vec3f(p, z));
}

struct Ray {
    origin: vec3f,
    direction: vec3f,
    state: RayState,
}

struct RayHit {
    position: vec3f,
    incident: vec3f,
}
fn ray_hit(ray: Ray) -> RayHit {
    return RayHit(ray.state.position, ray_incident(ray));
}
fn frag_ray_hit(p: vec2f, z: f32) -> RayHit {
    let position = vec3f(p, z);
    let incident = normalize(vec3f(0, 0, z));
    return RayHit(position, incident);
}

fn ray_initial_state(origin: vec3f) -> RayState {
    return RayState(origin, 0, 0);
}
struct RayState {
    position: vec3f,
    distance: f32,
    steps: i32,
}
