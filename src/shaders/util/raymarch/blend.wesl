struct SmoothMin {
    min: f32,
    blend: f32,
}
fn smin_quadratic(a: f32, b: f32, k: f32) -> f32 {
    let k_e = k * 4.0;
    let h = max(k_e - abs(a - b), 0.0) / k_e;
    return min(a, b) - h * h * k_e * (1.0 / 4.0);
}
// quadratic polynomial
fn smin_blend_quadratic(a: f32, b: f32, k: f32) -> vec2f {
    let h = 1.0 - min(abs(a - b) / (4.0 * k), 1.0);
    let w = h * h;
    let m = w * 0.5;
    let s = w * k;
    return select(vec2(b - s, 1.0 - m), vec2(a - s, m), a < b);
    // return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}

// cubic polynomial
fn smin_blend_cubic(a: f32, b: f32, k: f32) -> vec2f {
    let h = 1.0 - min(abs(a - b) / (6.0 * k), 1.0);
    let w = h * h * h;
    let m = w * 0.5;
    let s = w * k;
    return select(vec2(b - s, 1.0 - m), vec2(a - s, m), a < b);
    // return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}
