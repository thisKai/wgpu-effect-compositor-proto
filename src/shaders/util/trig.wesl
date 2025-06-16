const TAU = 6.28318530717958647692528676655900577;
const PI = 3.14159265358979323846264338327950288;
fn normalize_angle(angle: f32) -> f32 {
    return select(angle % TAU, TAU - (abs(angle) % TAU), angle < 0.0);
}
