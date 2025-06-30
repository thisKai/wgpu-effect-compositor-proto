fn circle_sd(p: vec2f, r: f32) -> f32 {
    return length(p) - r;
}

fn rect_sd(p: vec2f, b: vec2f) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

fn round_rect_sd(p: vec2f, b: vec2f, radius: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    return rect_sd(p, b - r) - r;
}

fn rect_round_sd(p: vec2f, b: vec2f, radius: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    return rect_sd(p, b - r) - r;
}

fn rect_round4_sd(p: vec2f, b: vec2f, radii: vec4f) -> f32 {
    var r = select(radii.zw, radii.xy, p.x > 0);
    r.x = select(r.y, r.x, p.y > 0);
    let q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0) + length(max(q, vec2f(0))) - r.x;
}
