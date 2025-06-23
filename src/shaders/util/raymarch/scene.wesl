import super::shape::{
    shape_count,
    shape_distance,
    shape_silhouette_distance,
    shape_normal,
    cuboid_sd,
    capsule_sd,
    MAX_DISTANCE,
};
import package::util::system::px;
import super::blend::{
    smin_quadratic,
    smin_blend_quadratic,
    smin_blend_cubic,
    smin_expo,
    smin_blend_expo,
    smin_circular,
};

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

fn scene_query(p: vec3f) -> SceneQuery {
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
fn scene_intersect_down(p: vec3f) -> SceneIntersect {
    let shape_c = shape_count();
    let tunnel_d = capsule_sd(p, p, vec3f(p.xy, 2), px(1));

    var closest_shape_index = shape_c;
    var min_d = MAX_DISTANCE;

    for (var i: u32 = 0; i < shape_c; i++) {
        let shape_d = max(shape_distance(p, i), tunnel_d);

        min_d = min(min_d, shape_d);

        if shape_d == min_d {
            closest_shape_index = i;
        }
    }

    let normal = select(
        vec3f(0, 0, -1),
        shape_normal(vec3f(p.xy, min_d), closest_shape_index, 1),
        closest_shape_index < shape_c,
    );

    return SceneIntersect(min_d, SceneIntersectShape(closest_shape_index, normal));
}

struct SceneIntersect {
    z: f32,
    closest_shape: SceneIntersectShape,
}
struct SceneIntersectShape {
    index: u32,
    normal: vec3f,
}

fn scene_min_distance(p: vec3f) -> f32 {
    let shape_c = shape_count();

    var closest_shape = shape_c;
    var min_d = MAX_DISTANCE;

    for (var i: u32 = 0; i <= shape_c; i++) {
        let shape_d = shape_distance(p, i);
        min_d = min(min_d, shape_d);
        closest_shape = select(closest_shape, i, min_d == shape_d);
    }
    // var min_d = shape_distance(p, 0);

    // for (var i: u32 = 1; i < shape_c; i++) {
    //     let shape_d = shape_distance(p, i);

    //     min_d = min(min_d, shape_d);
    // }
    return min_d;
}
fn scene_min_distance_down(p: vec3f) -> f32 {
    var min_d = scene_min_distance(p);
    let tunnel_d = capsule_sd(p, p, vec3f(p.xy, 1), px(0.005));
    // let tunnel_d = cuboid_sd(vec3f(0, 0, 0), vec3f(vec2f(px(0.0001)), 1));
    // let tunnel_d = 0.0;

    return max(min_d, tunnel_d);
}
fn scene_min_normal(p: vec3f) -> vec3f {
    let eps = px(0.1);
    let h = vec2(eps, 0);
    return normalize(vec3(scene_min_distance(p + h.xyy) - scene_min_distance(p - h.xyy),
        scene_min_distance(p + h.yxy) - scene_min_distance(p - h.yxy),
        scene_min_distance(p + h.yyx) - scene_min_distance(p - h.yyx)));
}
fn scene_smooth_distance(p: vec3f, k: f32) -> f32 {
    let shape_c = shape_count();

    var min_d = shape_distance(p, 0);

    for (var i: u32 = 1; i < shape_c; i++) {
        let shape_d = shape_distance(p, i);

        min_d = smin_expo(min_d, shape_d, k);
    }
    return min_d;
}
fn scene_smooth_distance_down(p: vec3f, k: f32) -> f32 {
    var min_d = scene_smooth_distance(p, k);
    let tunnel_d = cuboid_sd(vec3f(0, 0, -1), vec3f(vec2f(px(0.5)), 1));

    return max(min_d, tunnel_d);
}
fn scene_smooth_normal(p: vec3f, k: f32) -> vec3f {
    let shape_c = shape_count();

    var has_shapes = false;
    var min_d = 2.0;
    var normal = vec3f(0, 0, -1);

    for (var i: u32 = 0; i < shape_c; i++) {
        let shape_d = shape_distance(p, i);
        // if shape_d <= 0 {
        let shape_normal = shape_normal(vec3f(p.xy, p.z), i, 1);
        if has_shapes {
                // let blend = smin_blend_expo(min_d, shape_d, k);
                // min_d = blend.x;
            min_d = min(min_d, shape_d);
                // normal = mix(normal, shape_normal, blend.y);
            normal = select(normal, shape_normal, min_d == shape_d);
            // normal = shape_normal;
        } else {
            min_d = shape_d;
            has_shapes = shape_d <= k;
            // if has_shapes {
            normal = shape_normal;
            // }
        }
        // }
    }
    return normal;
}
fn scene_smooth_normal3(p: vec3f, k: f32) -> vec3f {
    let eps = px(0.1);
    let h = vec2(eps, 0);
    return normalize(vec3(scene_smooth_distance(p + h.xyy, k) - scene_smooth_distance(p - h.xyy, k),
        scene_smooth_distance(p + h.yxy, k) - scene_smooth_distance(p - h.yxy, k),
        scene_smooth_distance(p + h.yyx, k) - scene_smooth_distance(p - h.yyx, k)));
}
fn scene_smooth_normal2(p: vec3f, k: f32) -> vec3f {
    let shape_c = shape_count();

    var closest_shape = shape_c;
    var is_inside_shape = false;
    var is_within_smoothing_range = false;
    var min_d = 1.0;

    for (var i: u32 = 0; i < shape_c; i++) {
        let shape_d = shape_distance(p, i);
        min_d = min(min_d, shape_d);
        is_inside_shape = min_d < 0;
        is_within_smoothing_range = min_d < k;
        closest_shape = select(closest_shape, i, min_d == shape_d);
    }
}
fn scene_smooth_normal1(p: vec3f, k: f32) -> vec3f {
    let shape_c = shape_count();

    // let shape_0_d = shape_distance(p, 0);
    // var has_shapes_within_smoothing_distance = shape_0_d < px(1);
    // var has_shapes_without_smoothing = !has_shapes_within_smoothing_distance;

    // var has_shapes = shape_0_d < px(0.5);
    var has_shapes = false;
    // var is_grouped = false;

    var smin_d = 1.0;
    // var min_d = shape_0_d;
    var normal = vec3f(0, 0, -1);

    var in_shape = false;
    var in_smoothing_range = false;

    for (var i: u32 = 0; i < shape_c; i++) {
        let shape_i_d = shape_distance(p, i);
        let shape_i_sil_d = shape_silhouette_distance(p.xy, i);
        // let is_within_smoothing_distance = shape_i_d < px(1);

        let i_in_shape = shape_i_sil_d <= 0;
        let i_in_smoothing_range = shape_i_sil_d <= k;

        if i_in_smoothing_range {
            // let shape_i_d = shape_distance(p, i);
            let shape_i_normal = shape_normal(p, i, 1);

            if has_shapes {
                if i_in_shape && in_shape {
                //     smin_d = min(smin_d, shape_i_d);
                //     normal = select(normal, shape_i_normal, smin_d == shape_i_d);
                // } else {
                    // smin_d = smin_expo(smin_d, shape_i_d, k);
                    let b = smin_blend_cubic(smin_d, shape_i_d, k);
                    smin_d = b.x;
                    normal = normalize(mix(normal, shape_i_normal, b.y));
                }
            } else {
                smin_d = shape_i_d;
                normal = shape_i_normal;
                // min_d = shape_i_d;
                has_shapes = true;
            }
        }
        in_shape |= i_in_shape;
        in_smoothing_range |= i_in_smoothing_range;

        // if is_within_smoothing_distance {
        //     if has_shapes_within_smoothing_distance {
        //         smin_d = smin_expo(smin_d, shape_i_d, k);
        //     } else {
        //         smin_d = shape_i_d;
        //         min_d = shape_i_d;
        //         has_shapes_within_smoothing_distance = true;
        //     }
        // }
    }

    // return min(smin_d, min_d);
    return normal;
}

fn scene_silhouette_distance(p: vec2f) -> f32 {
    let shape_c = shape_count();
    var min_d = shape_silhouette_distance(p, 0);

    for (var i: u32 = 1; i < shape_c; i++) {
        let shape_d = shape_silhouette_distance(p, i);
        min_d = min(min_d, shape_d);
    }

    return min_d;
}
fn scene_silhouette_smooth_distance(p: vec2f, k: f32) -> f32 {
    let shape_c = shape_count();
    var min_d = shape_silhouette_distance(p, 0);

    for (var i: u32 = 1; i < shape_c; i++) {
        let shape_d = shape_silhouette_distance(p, i);
        min_d = smin_circular(min_d, shape_d, k);
    }

    return min_d;
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
