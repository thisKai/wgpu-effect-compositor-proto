fn ellipse_sd(p: vec2f, r: vec2f) -> f32 {
    let k1 = length(p / r);
    let k2 = length(p / (r * r));
    return k1 * (k1 - 1) / k2;
}
