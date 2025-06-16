fn p_norm_length2(v: vec2f, p: f32) -> f32 {
    let pow_p = pow(abs(v), vec2(p));
    return pow(pow_p.x + pow_p.y, 1.0 / p);
}
