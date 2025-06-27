fn smin(a: f32, b: f32, k: f32) -> f32 {
    return smin_cubic(a, b, k);
}
fn smin_blend(a: f32, b: f32, k: f32) -> vec2f {
    return smin_blend_cubic(a, b, k);
}


fn smin_expo(a: f32, b: f32, k: f32) -> f32 {
    let r = exp2(-a / k) + exp2(-b / k);
    return -k * log2(r);
}
fn smin_blend_expo(a: f32, b: f32, k: f32) -> vec2f {
    let f1 = exp2(-k * a);
    let f2 = exp2(-k * b);
    return vec2(-log2(f1 + f2) / k, f2);
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
}

// cubic polynomial
fn smin_cubic(a: f32, b: f32, k: f32) -> f32 {
    let k_e = k * 6.0;
    let h = max(k_e - abs(a - b), 0.0) / k_e;
    return min(a, b) - h * h * h * k_e * (1.0 / 6.0);
}
// cubic polynomial
fn smin_blend_cubic(a: f32, b: f32, k: f32) -> vec2f {
    let h = 1.0 - min(abs(a - b) / (6.0 * k), 1.0);
    let w = h * h * h;
    let m = w * 0.5;
    let s = w * k;
    return select(vec2(b - s, 1.0 - m), vec2(a - s, m), a < b);
}
