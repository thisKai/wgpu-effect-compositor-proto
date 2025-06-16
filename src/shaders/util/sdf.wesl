import super::norm::p_norm_length2;

fn rect_sd(p: vec2f, b: vec2f) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

fn squircle_rect_sd(p: vec2f, b: vec2f, radius: f32, e: f32) -> f32 {
    let r = min(radius, min(b.x, b.y));
    let d = abs(p) - (b - r);
    return p_norm_length2(max(d, vec2(0.0)), e) + min(max(d.x, d.y), 0.0) - r;
}
