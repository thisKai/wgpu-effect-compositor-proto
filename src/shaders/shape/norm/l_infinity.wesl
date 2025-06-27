fn length2_inf(v: vec2f) -> f32 {
    let abs_v = abs(v);
    return max(abs_v.x + abs_v.y);
}
fn length2_inf_p2(v: vec2f, p: vec2f) -> f32 {
    let pow_p = pow(abs(v), p);
    return max(pow_p.x, pow_p.y);
}

fn length3_inf(v: vec3f) -> f32 {
    let abs_v = abs(v);
    return max(abs_v.x + abs_v.y + abs_v.z);
}
