fn unit_circle(angle: f32) -> vec2f {
    return vec2f(cos(angle), sin(angle));
}
fn polygon_unit_circle(angle: f32, sides: f32) -> vec2f {
    let t = (sides / 4) * angle;
    return unit_circle(t);
}

fn unit_sphere(azimuthal_angle: f32, polar_angle: f32) -> vec3f {
    return vec3f(
        sin(polar_angle) * cos(azimuthal_angle),
        sin(polar_angle) * sin(azimuthal_angle),
        cos(polar_angle),
    );
}
