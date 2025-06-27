import package::shape::norm::lpm::length2_p3m;

fn superformula_sd(p: vec2f, m: f32, r: vec2f, n: vec3f) -> f32 {
    let k1 = length2_p3m(p / r, n, m);
    let k2 = length2_p3m(p / (r * r), n, m);
    return k1 * (k1 - 1) / k2;
}

fn superformula_symmetric_sd(p: vec2f, m: f32, r: f32, n: vec3f) -> f32 {
    return length2_p3m(p, n, m) - r;
}
