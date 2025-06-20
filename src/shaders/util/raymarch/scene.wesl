import super::shape::{
    shape_count,
    shape_distance,
    shape_silhouette_distance,
    MAX_DISTANCE,
};
import package::util::system::px;

fn scene_distance(p: vec3f) -> SceneQuery {
    let shape_c = shape_count();

    var closest_shape = shape_c;
    var min_d = MAX_DISTANCE;

    for (var i: u32 = 0; i <= shape_c; i++) {
        let shape_d = shape_distance(p, i);
        min_d = min(min_d, shape_d);
        closest_shape = select(closest_shape, i, min_d == shape_d);
    }

    return SceneQuery(closest_shape, min_d);
}
fn scene_silhouette_distance(p: vec2f) -> f32 {
    let shape_c = shape_count();
    var min_d = MAX_DISTANCE;

    for (var i: u32 = 0; i <= shape_c; i++) {
        let shape_d = shape_silhouette_distance(p, i);
        min_d = min(min_d, shape_d);
    }

    return min_d;
}
fn scene_silhouette_test(p: vec2f) -> bool {
    let shape_c = shape_count();

    for (var i: u32 = 0; i <= shape_c; i++) {
        let shape_d = shape_silhouette_distance(p, i);
        if shape_d < px(1) {
            return true;
        }
    }

    return false;
}

struct SceneQuery {
    closest_shape_index: u32,
    distance: f32,
}
fn SceneQuery_init() -> SceneQuery {
    return SceneQuery(shape_count(), MAX_DISTANCE);
}
fn SceneQuery_is_bg(q: SceneQuery) -> bool {
    return q.closest_shape_index == shape_count();
}
