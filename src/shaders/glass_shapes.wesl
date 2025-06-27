import super::util::{
    system::{viewport, viewport_cover_ratio, cursor, px, px2_rh},
    quad_vertex::{get_quad_vertex_sign, flip_y},
    anti_alias::edge_alpha,
};
import super::shape::{
    kind::CIRCLE,
    storage::bindings::{
        shape_count,
        shape_appearance,
    },
    sdf::{
        extrude::extrude_p,
        anti_alias::edge_alpha,
    },
    raymarching::{
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
    },
};


@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let vertex_sign = get_quad_vertex_sign(vertex_index);
    let vertex_pos = flip_y(vertex_sign);
    let texture_coord = 0.5 + 0.5 * flip_y(vertex_sign);

    out.position = vec4f(vertex_sign, 0, 1);
    out.frag_coord = vertex_pos;
    out.texture_coord = texture_coord;

    return out;
}

struct VertexOut {
    @builtin(position) position: vec4f,
    @location(0) frag_coord: vec2f,
    @location(1) texture_coord: vec2f,
}


@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4f {
    let silhouette_d = scene_silhouette_sd_sample(in.texture_coord);
    let alpha = edge_alpha(silhouette_d);

    if alpha <= 0 {
        discard;
    }

    var frag_ray = frag_ray_down(in.frag_coord);
    var d: f32;
    var result = ray_march(&frag_ray);

    if result == RAYMARCH_HIT {
        let normal = scene_normal(frag_ray.state.position);
        let ior = 1.5;
        let refracted_sample_coord = refraction_texture_coord(frag_ray, normal, 1.0 / ior);
        let sample = textureSample(wallpaper_texture, wallpaper_sampler, refracted_sample_coord).rgb;

        return vec4f(sqrt(sample), alpha);
    }

    let tint_color = textureSample(tint_color_texture, tint_color_sampler, in.texture_coord);

    return vec4f(sqrt(tint_color.rgb), tint_color.a * alpha);
}

fn refraction_texture_coord(collided_ray: Ray, normal: vec3f, ior: f32) -> vec2f {
    let ray_top_incident = ray_incident(collided_ray);
    let refract_in_dir = refract(ray_top_incident, normal, ior);
    var refract_in_ray = ray(collided_ray.state.position, refract_in_dir);

    let result = ray_march_to_bg(&refract_in_ray);
    let texture_coord_rh = refract_in_ray.state.position.xy;
    let texture_coord = 0.5 + 0.5 * texture_coord_rh;
    return texture_coord;
}

fn ray_march(ray: ptr<function, Ray>) -> RayMarchResult {
    for (var i = 0; i < MAX_STEPS; i++) {
        let scene_d = scene_sd(ray.state.position);

        ray_march_step(ray, scene_d);

        if scene_d < MIN_SURFACE_DISTANCE {
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
    let height = px(64);
    let extruded_d = extrude_p(d2, p.z - center_z, height, 5);
    return extruded_d - edge_r;
}
fn bg_sd(p: vec3f) -> f32 {
    return 1.0 - p.z;
}
fn scene_normal(p: vec3f) -> vec3f {
    let h = px(1);
    let k = vec2f(1, -1);
    return normalize(k.xyy * scene_sd(p + k.xyy * h) + k.yyx * scene_sd(p + k.yyx * h) + k.yxy * scene_sd(p + k.yxy * h) + k.xxx * scene_sd(p + k.xxx * h));
}

fn scene_silhouette_sd(p: vec2f) -> f32 {
    return scene_silhouette_sd_sample(0.5 + 0.5 * p);
}
fn scene_silhouette_sd_sample(texture_coord: vec2f) -> f32 {
    return textureSample(sdf_texture, sdf_sampler, texture_coord).r;
}

@group(1) @binding(0)
var wallpaper_texture: texture_2d<f32>;
@group(1) @binding(1)
var wallpaper_sampler: sampler;

@group(3) @binding(0)
var sdf_texture: texture_2d<f32>;
@group(3) @binding(1)
var sdf_sampler: sampler;

@group(3) @binding(2)
var tint_color_texture: texture_2d<f32>;
@group(3) @binding(3)
var tint_color_sampler: sampler;
