import super::unit::polygon_unit_circle;
import super::l_infinity::{length2_inf, length2_inf_p2};

fn length2_inf_m(v: vec2f, m: f32) -> f32 {
    let r = length(v);
    let phi = atan2(v.y, v.x);
    return length2_inf_m_polar(phi, r, m);
}
fn length2_inf_m_polar(phi: f32, r: f32, m: f32) -> f32 {
    let circle = polygon_unit_circle(phi, m);
    return length2_inf(r * circle);
}

fn length2_inf_p2m(v: vec2f, p: vec2f, m: f32) -> f32 {
    let r = length(v);
    let phi = atan2(v.y, v.x);
    return length2_inf_p2m_polar(phi, r, p, m);
}
fn length2_inf_p2m_polar(phi: f32, r: f32, p: vec2f, m: f32) -> f32 {
    let circle = polygon_unit_circle(phi, m);
    return length2_inf_p2(r * circle, p);
}
