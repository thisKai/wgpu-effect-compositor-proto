import super::{
    ray::{Ray, ray, frag_ray_down, ray_incident},
    march::{
        ray_march_step,
        RayMarch,
        RayMarchResult,
        RAYMARCH_MISSED_STEPS,
        RAYMARCH_MISSED_DISTANCE,
        RAYMARCH_HIT,
        MAX_STEPS,
        MAX_RAY_DISTANCE,
        MIN_SURFACE_DISTANCE,
    },
};
import package::shape::sdf::{
    extrude::extrude_p,
    anti_alias::edge_alpha,
};
import package::util::system::px;

fn ray_march(ray: ptr<function, Ray>) -> RayMarchResult {
    for (var i = 0; i < MAX_STEPS; i++) {
        let scene_d = scene_sd(ray.state.position);

        ray_march_step(ray, abs(scene_d));

        if abs(scene_d) < MIN_SURFACE_DISTANCE {
            return RAYMARCH_HIT;
        }
        if ray.state.distance > MAX_RAY_DISTANCE {
            return RAYMARCH_MISSED_DISTANCE;
        }
    }
    return RAYMARCH_MISSED_STEPS;
}
fn ray_march_to_bg(ray: ptr<function, Ray>) -> RayMarchResult {
    for (var i = 0; i < MAX_STEPS; i++) {
        let bg_d = bg_sd(ray.state.position);

        ray_march_step(ray, bg_d);

        if bg_d < MIN_SURFACE_DISTANCE {
            return RAYMARCH_HIT;
        }
        if ray.state.distance > MAX_RAY_DISTANCE {
            return RAYMARCH_MISSED_DISTANCE;
        }
    }
    return RAYMARCH_MISSED_STEPS;
}

fn scene_sd(p: vec3f) -> f32 {
    let edge_r = px(32);
    let d2 = scene_silhouette_sd(p.xy) + edge_r;
    let center_z = 1.0 - px(64);
    let height = px(32);
    let extruded_d = extrude_p(d2, p.z - center_z, height, 4);
    return extruded_d - edge_r;
}
fn bg_sd(p: vec3f) -> f32 {
    return 1.0 - p.z;
}

fn scene_normal(p: vec3f) -> vec3f {
    return compute_normal(p);
}
fn compute_normal(p: vec3f) -> vec3f {
    let h = px(1);
    let k = vec2f(1, -1);
    return normalize(k.xyy * scene_sd(p + k.xyy * h) + k.yyx * scene_sd(p + k.yyx * h) + k.yxy * scene_sd(p + k.yxy * h) + k.xxx * scene_sd(p + k.xxx * h));
}

fn normal_map(texture_coord_rh: vec2f) -> vec3f {
    return normal_map_sample(0.5 + 0.5 * texture_coord_rh) * 2 - 1;
}
fn normal_map_back_inside(texture_coord_rh: vec2f) -> vec3f {
    let normal_front = normal_map(texture_coord_rh);
    return vec3f(-normal_front.xy, normal_front.z);
}
fn normal_map_sample(texture_coord: vec2f) -> vec3f {
    return textureSample(normal_map_texture, normal_map_sampler, texture_coord).xyz;
}

fn normal_map_and_depth(texture_coord_rh: vec2f) -> NormalAndDepth {
    let sample = normal_map_and_depth_sample(0.5 + 0.5 * texture_coord_rh);
    return NormalAndDepth(sample.xyz * 2 - 1, sample.w);
}
struct NormalAndDepth {
    normal: vec3f,
    depth: f32,
}
fn normal_map_and_depth_sample(texture_coord: vec2f) -> vec4f {
    return textureSample(normal_map_texture, normal_map_sampler, texture_coord);
}

fn scene_silhouette_sd(p: vec2f) -> f32 {
    return scene_silhouette_sd_sample(0.5 + 0.5 * p);
}
fn scene_silhouette_sd_sample(texture_coord: vec2f) -> f32 {
    return textureSample(sdf_texture, sdf_sampler, texture_coord).r;
}

fn tint_color(texture_coord: vec2f) -> vec4f {
    return textureSample(tint_color_texture, tint_color_sampler, texture_coord);
}


@group(2) @binding(0)
var sdf_texture: texture_2d<f32>;
@group(2) @binding(1)
var sdf_sampler: sampler;

@group(2) @binding(2)
var tint_color_texture: texture_2d<f32>;
@group(2) @binding(3)
var tint_color_sampler: sampler;

@group(3) @binding(0)
var normal_map_texture: texture_2d<f32>;
@group(3) @binding(1)
var normal_map_sampler: sampler;
