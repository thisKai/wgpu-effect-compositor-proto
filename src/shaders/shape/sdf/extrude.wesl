import package::shape::norm::lp::length2_p;
import package::shape::norm::lpm::length2_p3m;

fn extrude(d: f32, z: f32, h: f32) -> f32 {
    let w = vec2(d, abs(z) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, vec2(0.0)));
}
fn extrude_p(d: f32, z: f32, h: f32, p: f32) -> f32 {
    let w = vec2(d, abs(z) - h);
    return min(max(w.x, w.y), 0.0) + length2_p(max(w, vec2(0.0)), p);
}
fn extrude_p3m(d: f32, z: f32, h: f32, p: vec3f, m: f32) -> f32 {
    let w = vec2(d, abs(z) - h);
    return min(max(w.x, w.y), 0.0) + length2_p3m(max(w, vec2(0.0)), p, m);
}
