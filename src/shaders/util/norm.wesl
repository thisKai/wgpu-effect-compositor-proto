fn p_norm_length2(v: vec2f, p: f32) -> f32 {
    let pow_p = pow(abs(v), vec2(p));
    return pow(pow_p.x + pow_p.y, 1.0 / p);
}
fn p_norm_length22(v: vec2f, p: vec2f) -> f32 {
    let pow_p = pow(abs(v), p);
    return pow(pow_p.x + pow_p.y, 1.0 / length(p));
}


fn p_norm_length3(v: vec3f, p: f32) -> f32 {
    let pow_p = pow(abs(v), vec3(p));
    return pow(pow_p.x + pow_p.y + pow_p.z, 1 / p);
}
fn p_norm_length33(v: vec3f, p: vec3f) -> f32 {
    let pow_p = pow(abs(v), p);
    return pow(pow_p.x + pow_p.y + pow_p.z, 1 / length(p));
}
