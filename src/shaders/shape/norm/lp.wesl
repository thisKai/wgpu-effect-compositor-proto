fn length2_p(v: vec2f, p: f32) -> f32 {
    let pow_v = pow(abs(v), vec2(p));
    return pow(pow_v.x + pow_v.y, 1.0 / p);
}

fn length2_p3(v: vec2f, p: vec3f) -> f32 {
    let pow_v = pow(abs(v), p.yz);
    return pow(pow_v.x + pow_v.y, 1.0 / p.x);
}

fn length3_p(v: vec3f, p: f32) -> f32 {
    let pow_v = pow(abs(v), vec3(p));
    return pow(pow_v.x + pow_v.y + pow_v.z, 1.0 / p);
}
