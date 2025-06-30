import package::shape::norm::lp::length2_p;

fn squircle_sd(p: vec2f, r: f32, n: f32) -> f32 {
    return length2_p(p, n) - r;
}

fn superellipse_sd(p: vec2f, r: vec2f, n: f32) -> f32 {
    let k1 = length2_p(p / r, n);
    let k2 = length2_p(p / (r * r), n);
    return k1 * (k1 - 1) / k2;
}

fn rect_p_sd(p: vec2f, b: vec2f, n: f32) -> f32 {
    let d = abs(p) - b;
    return length2_p(max(d, vec2(0.0)), n) + min(max(d.x, d.y), 0.0);
}

fn squircle_rect_sd(p: vec2f, b: vec2f, radius: f32, n: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    return rect_p_sd(p, b - r, n) - r;
}

fn rect_p_round_sd(p: vec2f, b: vec2f, radius: f32, n: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    return rect_p_sd(p, b - r, n) - r;
}

fn rect_p_round4_sd(p: vec2f, b: vec2f, radii: vec4f, n: f32) -> f32 {
    var r = select(radii.zw, radii.xy, p.x > 0);
    r.x = select(r.y, r.x, p.y > 0);
    let q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0) + length2_p(max(q, vec2f(0)), n) - r.x;
}
