fn sat(rgb: vec3f, intensity: f32) -> vec3f {
    let l = vec3(0.2125, 0.7154, 0.0721);
    let grayscale = vec3(dot(rgb, l));
    return mix(grayscale, rgb, intensity);
}

fn rygcbv_r(rgb: vec3f) -> f32 {
    return rgb.r / 2;
}
fn rygcbv_g(rgb: vec3f) -> f32 {
    return rgb.g / 2;
}
fn rygcbv_b(rgb: vec3f) -> f32 {
    return rgb.b / 2;
}
fn rygcbv_y(rgb: vec3f) -> f32 {
    let r = rgb.r;
    let g = rgb.g;
    let b = rgb.b;
    return ((2 * r) + (2 * g) - b) / 6;
}
fn rygcbv_c(rgb: vec3f) -> f32 {
    let r = rgb.r;
    let g = rgb.g;
    let b = rgb.b;
    return ((2 * g) + (2 * b) - r) / 6;
}
fn rygcbv_v(rgb: vec3f) -> f32 {
    let r = rgb.r;
    let g = rgb.g;
    let b = rgb.b;
    return ((2 * b) + (2 * r) - g) / 6;
}
fn rygcbv_rgb(r: f32, y: f32, g: f32, c: f32, b: f32, v: f32) -> vec3f {
    let out_r = r + ((2 * v) + (2 * y) - c) / 3;
    let out_g = g + ((2 * y) + (2 * c) - v) / 3;
    let out_b = b + ((2 * c) + (2 * v) - y) / 3;

    return vec3f(out_r, out_g, out_b);
}
