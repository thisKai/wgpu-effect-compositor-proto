import super::util::{
    system::px,
    quad_vertex::{get_quad_vertex_sign, flip_y},
    color::{
        sat,
        rygcbv_r,
        rygcbv_g,
        rygcbv_b,
        rygcbv_y,
        rygcbv_c,
        rygcbv_v,
        rygcbv_rgb,
    },
};
import super::shape::{
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
        let sample = chromatic_refraction_sample(frag_ray, normal, 1.0 / ior);

        return vec4f(sqrt(sample), alpha);
    }

    let tint_color = textureSample(tint_color_texture, tint_color_sampler, in.texture_coord);

    return vec4f(sqrt(tint_color.rgb), tint_color.a * alpha);
}

fn chromatic_refraction_sample(collided_ray: Ray, normal: vec3f, ior: f32) -> vec3f {
    let ior_shift = 0.1;
    let ior_ryg = (vec3f(0, 1, 2) * ior_shift) + ior;
    let ior_cbv = (vec3f(3, 4, 5) * ior_shift) + ior;

    let ior_rgb = vec3f(ior_ryg.r, ior_ryg.z, ior_cbv.y);
    let ior_ycv = vec3f(ior_ryg.y, ior_cbv.xz);

    let refraction_r = refraction_texture_coord(collided_ray, normal, 1.0 / ior_rgb.r);
    let refraction_g = refraction_texture_coord(collided_ray, normal, 1.0 / ior_rgb.g);
    let refraction_b = refraction_texture_coord(collided_ray, normal, 1.0 / ior_rgb.b);

    let refraction_y = refraction_texture_coord(collided_ray, normal, 1.0 / ior_ycv.r);
    let refraction_c = refraction_texture_coord(collided_ray, normal, 1.0 / ior_ycv.g);
    let refraction_v = refraction_texture_coord(collided_ray, normal, 1.0 / ior_ycv.b);

    let sample_r = rygcbv_r(textureSample(wallpaper_texture, wallpaper_sampler, refraction_r).rgb);
    let sample_g = rygcbv_g(textureSample(wallpaper_texture, wallpaper_sampler, refraction_g).rgb);
    let sample_b = rygcbv_b(textureSample(wallpaper_texture, wallpaper_sampler, refraction_b).rgb);

    let sample_y = rygcbv_y(textureSample(wallpaper_texture, wallpaper_sampler, refraction_r).rgb);
    let sample_c = rygcbv_c(textureSample(wallpaper_texture, wallpaper_sampler, refraction_g).rgb);
    let sample_v = rygcbv_v(textureSample(wallpaper_texture, wallpaper_sampler, refraction_b).rgb);

    let sample = rygcbv_rgb(sample_r, sample_y, sample_g, sample_c, sample_b, sample_v);
    return sat(sample, 1.25);
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
