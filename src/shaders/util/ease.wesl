fn ease_in_sine(t: f32) -> f32 {
    return 1 - cos((t * radians(180)) / 2);
}
fn ease_out_sine(t: f32) -> f32 {
    return sin((t * radians(180)) / 2);
}
fn ease_in_out_sine(t: f32) -> f32 {
    return -(cos(radians(180) * t) - 1) / 2;
}
