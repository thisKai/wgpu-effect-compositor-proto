fn p_norm_length2(v: vec2f, p: f32) -> f32 {
    let pow_p = pow(abs(v), vec2(p));
    return pow(pow_p.x + pow_p.y, 1.0 / p);
}
fn inf_norm_length2(v: vec2f) -> f32 {
    let abs_v = abs(v);
    return max(abs_v.x + abs_v.y);
}
fn p_norm_length22(v: vec2f, p: vec2f) -> f32 {
    let pow_p = pow(abs(v), p);
    return pow(pow_p.x + pow_p.y, 1.0 / length(p));
}
fn p3_m_norm_length2(v: vec2f, p: vec3f, m: f32) -> f32 {
    let phi = atan2(v.y, v.x);
    let r = length(v);

    let t = m / 4 * phi;
    let circle = vec2f(cos(t), sin(t));

    return p3_norm_length2(r * circle, p);
}
fn inf_p2_m_norm_length2(v: vec2f, p: vec2f, m: f32) -> f32 {
    let phi = atan2(v.y, v.x);
    let r = length(v);

    let t = m / 4 * phi;
    let circle = vec2f(cos(t), sin(t));

    return inf_p2_norm_length2(r * circle, p);
}
fn p3_norm_length2(v: vec2f, p: vec3f) -> f32 {
    let pow_p = pow(abs(v), p.yz);
    return pow(pow_p.x + pow_p.y, 1.0 / p.x);
}
fn inf_p2_norm_length2(v: vec2f, p: vec2f) -> f32 {
    let pow_p = pow(abs(v), p);
    return max(pow_p.x + pow_p.y);
}


fn p_norm_length3(v: vec3f, p: f32) -> f32 {
    let pow_p = pow(abs(v), vec3(p));
    return pow(pow_p.x + pow_p.y + pow_p.z, 1 / p);
}
fn p_norm_length33(v: vec3f, p: vec3f) -> f32 {
    let pow_p = pow(abs(v), p);
    return pow(pow_p.x + pow_p.y + pow_p.z, 1 / length(p));
}

fn p_norm_extrusion(d: f32, z: f32, h: f32, n: f32) -> f32 {
    let w = vec2(d, abs(z) - h);
    return min(max(w.x, w.y), 0.0) + p_norm_length2(max(w, vec2(0.0)), n);
}

fn p_norm_y_intersect2(x: f32, center: vec2f, r: f32, p: f32) -> f32 {
    let local_y = pow(pow(r, p) - pow(abs(x - center.x), p), 1.0 / p);

    let add = center.y + local_y;
    let sub = center.y - local_y;

    let add_d = abs(x - add);
    let sub_d = abs(x - sub);

    return select(add, sub, add_d > sub_d);
}
// fn p_norm_z_intersect2(p_z: f32, center_z: f32, center_d: f32, length_xy: f32, r: f32, e: f32) -> f32 {
//     return p_norm_y_intersect2(p_z, vec2f(center_d, center_z));
// }

fn p_norm_z_intersect(p_z: f32, center_z: f32, center_d: f32, length_xy: f32, r: f32, e: f32) -> f32 {
    let local_z = pow(pow(r, n) - pow(abs(length_xy - center_d), n), 1.0 / n);

    let add = center_z + local_z;
    let sub = center_z - local_z;

    let add_d = abs(p_z - add);
    let sub_d = abs(p_z - sub);

    return select(
        add,
        sub,
        add_d > sub_d,
    );
}
