import super::shape::{
    shape_count,
    shape_distance,
    MAX_DISTANCE,
};

fn scene_distance(p: vec3f) -> f32 {
    var min_d = MAX_DISTANCE;

    for (var i: u32 = 0; i < shape_count(); i++) {
        let shape_d = shape_distance(p, i);
        min_d = min(min_d, shape_d);
    }

    return min_d;
}
