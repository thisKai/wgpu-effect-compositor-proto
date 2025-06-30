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
    sdf::anti_alias::edge_alpha,
    raymarching::{
        ray::{
            Ray,
            ray,
            frag_ray_down,
            ray_incident,
            frag_ray_incident,
            RayHit,
            ray_hit,
            frag_ray_hit,
        },
        march::{ray_march_step, RAYMARCH_HIT},
        scene::{
            ray_march,
            ray_march_to_bg,
            scene_normal,
            normal_map_and_depth,
            normal_map, normal_map_back_inside,
            scene_silhouette_sd_sample,
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

    let normal_depth_front_out = normal_map_and_depth(in.frag_coord);
    let normal_front_out = normal_depth_front_out.normal;
    let hit_front_out = frag_ray_hit(in.frag_coord, normal_depth_front_out.depth);

    let ior = 1.5;

    // var sample = chromatic_refraction_sample(hit_front_out, normal_front_out, 1.0 / ior);

    var sample = double_chromatic_refraction_sample(hit_front_out, normal_front_out, 1.0 / ior);

    // let view_dir = frag_ray.direction;

    // let fresnel_intensity = fresnel(view_dir, normal);

    // let light_dir = normalize(vec3f(-32, -128, 1));
    // let back_inside_light_dir = normalize(vec3f(-16, -64, 2));

    // let diffuse_product = max(0.0, dot(front_normal, light_dir));
    // let back_inside_diffuse_product = max(0.0, dot(-normal2, back_inside_light_dir));

    // let half_dir = normalize(view_dir + light_dir);
    // let specular_coefficient = 32.0;
    // let specular_product = max(0.0, dot(front_normal, half_dir));
    // let specular_intensity = pow(specular_product, specular_coefficient);

    // let back_inside_half_dir = normalize(view_dir + back_inside_light_dir);
    // let back_inside_specular_coefficient = 32.0;
    // let back_inside_specular_product = max(0.0, dot(-normal2, back_inside_half_dir));
    // let back_inside_specular_intensity = pow(back_inside_specular_product, back_inside_specular_coefficient);

    // let tint_color = textureSample(tint_color_texture, tint_color_sampler, in.texture_coord);

    // sample *= 1 + (2 * fresnel_intensity);
    // sample += vec3f(1) * fresnel_intensity;

    // sample += tint_color.rgb * diffuse_product;
    // sample += tint_color.rgb * back_inside_diffuse_product;
    // sample += tint_color.rgb * max(diffuse_product, back_inside_diffuse_product);

    // sample *= 1 + (4 * specular_intensity);
    // sample *= 1 + (4 * back_inside_specular_intensity);
    // sample += vec3f(1) * specular_intensity;
    // sample += vec3f(1) * back_inside_specular_intensity;

    // sample += vec3f(1) * (specular_intensity + back_inside_specular_intensity);
    // sample += tint_color.rgb * back_inside_specular_intensity;


    return vec4f(sqrt(sample) * alpha, alpha);
}

fn double_chromatic_refraction_sample(hit: RayHit, normal: vec3f, ior: f32) -> vec3f {
    let ior_shift = ior / 10;
    let ior_ryg = (vec3f(0, 1, 2) * ior_shift) + ior;
    let ior_cbv = (vec3f(3, 4, 5) * ior_shift) + ior;

    let ior_rgb = vec3f(ior_ryg.r, ior_ryg.z, ior_cbv.y);
    let ior_ycv = vec3f(ior_ryg.y, ior_cbv.xz);

    let refraction_r = double_refraction_texture_coord(hit, normal, ior_rgb.r);
    let refraction_g = double_refraction_texture_coord(hit, normal, ior_rgb.g);
    let refraction_b = double_refraction_texture_coord(hit, normal, ior_rgb.b);

    let refraction_y = double_refraction_texture_coord(hit, normal, ior_ycv.r);
    let refraction_c = double_refraction_texture_coord(hit, normal, ior_ycv.g);
    let refraction_v = double_refraction_texture_coord(hit, normal, ior_ycv.b);

    let sample_r = rygcbv_r(textureSample(wallpaper_texture, wallpaper_sampler, refraction_r).rgb);
    let sample_g = rygcbv_g(textureSample(wallpaper_texture, wallpaper_sampler, refraction_g).rgb);
    let sample_b = rygcbv_b(textureSample(wallpaper_texture, wallpaper_sampler, refraction_b).rgb);

    let sample_y = rygcbv_y(textureSample(wallpaper_texture, wallpaper_sampler, refraction_r).rgb);
    let sample_c = rygcbv_c(textureSample(wallpaper_texture, wallpaper_sampler, refraction_g).rgb);
    let sample_v = rygcbv_v(textureSample(wallpaper_texture, wallpaper_sampler, refraction_b).rgb);

    let sample = rygcbv_rgb(sample_r, sample_y, sample_g, sample_c, sample_b, sample_v);
    return sat(sample, 1.5);
}
fn double_refraction_texture_coord(hit: RayHit, normal: vec3f, ior: f32) -> vec2f {
    return 0.5 + 0.5 * double_refraction_coord(hit, normal, ior);
}
fn double_refraction_coord(hit: RayHit, normal: vec3f, ior: f32) -> vec2f {
    let refract_in_dir = refract(hit.incident, normal, ior);
    var refract_in_ray = ray(hit.position, refract_in_dir);

    ray_march_step(&refract_in_ray, AFTER_MARCH_START_SHIFT);
    let back_inside_result = ray_march(&refract_in_ray);

    // let normal2 = scene_normal(refract_in_ray.state.position);
    let normal_back_inside = normal_map_back_inside(refract_in_ray.state.position.xy);
    let ray_back_incident = ray_incident(refract_in_ray);

    // let refract_out_dir = refract(ray_back_incident, vec3(-normal2.xy, -normal2.z), 1.0 / ior);
    let refract_out_dir = refract(ray_back_incident, normal_back_inside, 1.0 / ior);
    var refract_out_ray = ray(refract_in_ray.state.position, refract_out_dir);
    ray_march_step(&refract_out_ray, AFTER_MARCH_START_SHIFT);
    let bg_result = ray_march_to_bg(&refract_out_ray);

    let texture_coord_rh = refract_out_ray.state.position.xy;
    return texture_coord_rh;
}
const AFTER_MARCH_START_SHIFT = px(8);

fn chromatic_refraction_sample(hit: RayHit, normal: vec3f, ior: f32) -> vec3f {
    let ior_shift = ior / 10;
    let ior_ryg = (vec3f(0, 1, 2) * ior_shift) + ior;
    let ior_cbv = (vec3f(3, 4, 5) * ior_shift) + ior;

    let ior_rgb = vec3f(ior_ryg.r, ior_ryg.z, ior_cbv.y);
    let ior_ycv = vec3f(ior_ryg.y, ior_cbv.xz);

    let refraction_r = refraction_texture_coord(hit, normal, ior_rgb.r);
    let refraction_g = refraction_texture_coord(hit, normal, ior_rgb.g);
    let refraction_b = refraction_texture_coord(hit, normal, ior_rgb.b);

    let refraction_y = refraction_texture_coord(hit, normal, ior_ycv.r);
    let refraction_c = refraction_texture_coord(hit, normal, ior_ycv.g);
    let refraction_v = refraction_texture_coord(hit, normal, ior_ycv.b);

    let sample_r = rygcbv_r(textureSample(wallpaper_texture, wallpaper_sampler, refraction_r).rgb);
    let sample_g = rygcbv_g(textureSample(wallpaper_texture, wallpaper_sampler, refraction_g).rgb);
    let sample_b = rygcbv_b(textureSample(wallpaper_texture, wallpaper_sampler, refraction_b).rgb);

    let sample_y = rygcbv_y(textureSample(wallpaper_texture, wallpaper_sampler, refraction_r).rgb);
    let sample_c = rygcbv_c(textureSample(wallpaper_texture, wallpaper_sampler, refraction_g).rgb);
    let sample_v = rygcbv_v(textureSample(wallpaper_texture, wallpaper_sampler, refraction_b).rgb);

    let sample = rygcbv_rgb(sample_r, sample_y, sample_g, sample_c, sample_b, sample_v);
    return sat(sample, 1.5);
}
fn refraction_texture_coord(hit: RayHit, normal: vec3f, ior: f32) -> vec2f {
    return 0.5 + 0.5 * refraction_coord(hit, normal, ior);
}
fn refraction_coord(hit: RayHit, normal: vec3f, ior: f32) -> vec2f {
    let refract_in_dir = refract(hit.incident, normal, ior);
    var refract_in_ray = ray(hit.position, refract_in_dir);

    let result = ray_march_to_bg(&refract_in_ray);
    let texture_coord_rh = refract_in_ray.state.position.xy;
    return texture_coord_rh;
}

fn fresnel(eye_vector: vec3f, normal: vec3f) -> f32 {
    return pow(1.0 + dot(eye_vector, normal), 5.0);
}


@group(4) @binding(0)
var wallpaper_texture: texture_2d<f32>;
@group(4) @binding(1)
var wallpaper_sampler: sampler;
