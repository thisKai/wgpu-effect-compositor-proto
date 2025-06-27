fn aspect_ratio_x(size: vec2f) -> f32 {
    return size.x / size.y;
}
fn aspect_ratio_2(size: vec2f) -> vec2f {
    return size / size.y;
}

fn min2(size: vec2f) -> f32 {
    return min(size.x, size.y);
}
fn max2(size: vec2f) -> f32 {
    return max(size.x, size.y);
}

fn ratio_by_min(size: vec2f) -> vec2f {
    let min_dimension = min2(size);
    return size / min_dimension;
}
fn ratio_by_max(size: vec2f) -> vec2f {
    let max_dimension = max2(size);
    return size / max_dimension;
}

fn size_range(size: vec2f) -> Range {
    let size_min = min2(size);
    let size_max = max2(size);

    return Range(size_min, size_max);
}
fn ratio_range(size: vec2f) -> Range {
    let size_r = size_range(size);

    return Range(size_r.min / size_r.max, size_r.max / size_r.min);
}
struct Range {
    min: f32,
    max: f32,
}
