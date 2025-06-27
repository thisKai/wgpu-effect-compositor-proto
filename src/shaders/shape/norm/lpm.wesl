import super::unit::polygon_unit_circle;
import super::lp::length2_p3;

fn length2_p3m(v: vec2f, p: vec3f, m: f32) -> f32 {
    let phi = atan2(v.y, v.x);
    let r = length(v);
    return length2_p3m_polar(phi, r, p, m);
}
fn length2_p3m_polar(phi: f32, r: f32, p: vec3f, m: f32) -> f32 {
    let circle = polygon_unit_circle(phi, m);

    return length2_p3(r * circle, p);
}
