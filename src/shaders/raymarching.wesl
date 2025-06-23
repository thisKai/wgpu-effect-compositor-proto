import super::util::{
    system::{viewport, viewport_cover_ratio, cursor, px},
    quad_vertex::{get_quad_vertex_sign, flip_y},
    anti_alias::edge_alpha,
};
import super::util::color::{
    rygcbv_r,
    rygcbv_g,
    rygcbv_b,
    rygcbv_y,
    rygcbv_c,
    rygcbv_v,
    rygcbv_rgb,
};
import super::util::raymarch::{
    ray::Ray,
    march::{
        raymarch,
        is_hit,
        hit_alpha,
        hit_bg,
        RayMarchOptions_scene,
        RayMarchOptions_bg,
        RayMarchOptions_shape,
        RayMarchOptions_inside_shape,
    },
    scene::{
        scene_silhouette_distance,
        scene_silhouette_smooth_distance,
        scene_min_distance,
        scene_min_distance_down,
        scene_min_normal,
        scene_smooth_distance,
        scene_smooth_distance_down,
        scene_smooth_normal,
        scene_intersect_down,
    },
    shape::{plane_intersect_distance, capsule_sd},
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let vertex_sign = get_quad_vertex_sign(vertex_index);
    let vertex_pos = flip_y(vertex_sign * viewport_cover_ratio());

    out.position = vec4f(vertex_sign, 0, 1);
    out.uv = vertex_pos;
    out.tex_coords = 0.5 + 0.5 * flip_y(vertex_pos);

    return out;
}

struct VertexOut {
    @builtin(position) position: vec4f,
    @location(0) uv: vec2f,
    @location(1) tex_coords: vec2f,
}


@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4f {
    let smoothing = px(2);
    let silhouette_d = scene_silhouette_distance(in.uv);
    // let silhouette_d = scene_silhouette_smooth_distance(in.uv, smoothing);
    if silhouette_d > px(0.5) {
        discard;
    } else if false {
        let view_dir = vec3f(0, 0, 1);
        let light_pos = vec3f(0, -16, -8);
        let back_light_pos = vec3f(0, -32, -64);

        let ray_origin = vec3f(in.uv, 0);
        let d = scene_min_distance_down(ray_origin);
        let scene = scene_intersect_down(ray_origin);

        let ray = Ray(ray_origin, vec3f(0, 0, 1));
        let r = raymarch(ray, RayMarchOptions_scene());
        // let d = scene_smooth_distance_down(ray_origin, smoothing);

        let top_surface_pos = vec3f(in.uv, d);

        let ior = 1.5;

        let top_surface_incident = normalize(top_surface_pos - ray_origin);
        // let top_surface_normal = scene_min_normal(vec3f(top_surface_pos.xy, top_surface_pos.z));
        let top_surface_normal = scene_smooth_normal(vec3f(top_surface_pos.xy, top_surface_pos.z), smoothing);
        // let refraction_in_dir = refract(top_surface_incident, top_surface_normal, 1.0 / ior);
        // let refraction_in_ray = Ray(top_surface_pos, refraction_in_dir);
        // let bg_intersect_d = plane_intersect_distance(top_surface_pos, refraction_in_dir, vec4f(0, 0, -1, 1));
        // let bg_intersect_pos = top_surface_pos + refraction_in_dir * bg_intersect_d;

        // let ray_tunnel = capsule_sd(top_surface_pos, top_surface_pos + refraction_in_dir * px(64), bg_intersect_pos, px(4));
        // let inside_d = scene_smooth_distance(top_surface_pos + refraction_in_dir * px(64), smoothing);
        // let back_intersect_d = max(ray_tunnel, -inside_d);
        // let back_intersect_pos = top_surface_pos * refraction_in_dir * back_intersect_d;
        // let back_surface_inside_normal = scene_smooth_normal(back_intersect_pos, smoothing);

        // let refraction_to_bottom_surface = raymarch(refraction_in_ray, RayMarchOptions_scene());
        // // let refraction_to_bg = raymarch(refraction_in_ray, RayMarchOptions_bg());

        // let back_normal_inside = refraction_to_bottom_surface.normal;
        // let back_normal = -refraction_to_bottom_surface.normal;
        // let bottom_surface_normal = vec3f(-top_surface_pos.xy, 1 - top_surface_pos.z);

        // let sample_coord = bg_intersect_pos.xy;
        // let tex_coord = 0.5 + 0.5 * sample_coord;
        // let sample = textureSample(t_diffuse, s_diffuse, tex_coord).rgb;

        // let light_dir = normalize(light_pos - top_surface_pos);
        // let diffuse_product = max(0.0, dot(top_surface_normal, light_dir));

        // let back_light_dir = normalize(back_light_pos - top_surface_pos);
        // let back_diffuse_product = max(0.0, dot(back_normal_inside, back_light_dir));

        // let half_dir = normalize(view_dir + light_dir);
        // let specular_coefficient = 2.0;
        // let specular_product = max(0.0, dot(top_surface_normal, half_dir));
        // let specular_intensity = pow(specular_product, specular_coefficient);

        // let back_half_dir = normalize(view_dir + back_light_dir);
        // let back_specular_coefficient = 2.0;
        // let back_specular_product = max(0.0, dot(back_normal_inside, back_half_dir));
        // let back_specular_intensity = pow(back_specular_product, back_specular_coefficient);

        // let fresnel_intensity = fresnel(top_surface_incident, top_surface_normal);

        // let fresnel_specular = (fresnel_intensity * 64) + (fresnel_intensity * ((specular_intensity * 128) + (back_specular_intensity * 8)));
        // // let light_strength = 0 + (diffuse_product * 1) + (specular_product * 1) + fresnel_intensity * 1;
        // let light_strength = (2) + (((diffuse_product * 2) + (back_diffuse_product * 1) + max(specular_intensity * 128, back_specular_intensity * 8) + fresnel_specular));
        // // let rgb = (sample.rgb * 2) + (sample.rgb * ((diffuse_product * 2) + (back_diffuse_product * 1) + max(specular_intensity * 32, back_specular_intensity * 8) + fr_i));
        // let lit_sample = sample.rgb * light_strength;

        let alpha = edge_alpha(silhouette_d);

        // return vec4f(0.5 + 0.5 * -vec3f(scene.z, f32(scene.closest_shape.index) / 4, 0), alpha);
        // return vec4f(((vec3f(0, 0, (r.state.position.z) / px(128)) + (vec3f(0, 0, scene.z) * 0))), alpha);

        return vec4f((0.5 + 0.5 * r.normal), alpha);
        // return vec4f(sqrt(sample + lit_sample), alpha);
    }

    let view_dir = vec3f(0, 0, 1);
    let light_pos = vec3f(0, -16, -8);

    let ray = Ray(vec3f(in.uv, 0), vec3f(0, 0, 1));
    let r = raymarch(ray, RayMarchOptions_scene());

    if is_hit(r) && !hit_bg(r) {
    // if is_hit(r) {
        let ior = 1.5;
        let ior_shift = 0.1;
        // let ior_rgb = vec3f(ior_shift, 0, -ior_shift) + ior;
        let ior_ryg = vec3f(3 * ior_shift, 2 * ior_shift, ior_shift) + ior;
        let ior_cbv = vec3f(0, -ior_shift, -2 * ior_shift) + ior;

        let ior_rgb = vec3f(ior_ryg.r, ior_ryg.z, ior_cbv.y) + ior;
        let ior_ycv = vec3f(ior_ryg.y, ior_cbv.xz);

        let refraction_in_incident_vec = normalize(r.state.position - ray.origin);

        let refraction = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior);

        // let refraction_r = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_rgb.r);
        // let refraction_g = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_rgb.g);
        // let refraction_b = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_rgb.b);

        let refraction_r = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_rgb.r);
        let refraction_g = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_rgb.g);
        let refraction_b = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_rgb.b);

        let refraction_y = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_ycv.r);
        let refraction_c = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_ycv.g);
        let refraction_v = refraction_tex_coord_normal(r.state.position, ray.origin, r.normal, 1.0 / ior_ycv.b);
        // let refraction_in_dir = refract(refraction_in_incident_vec, r.normal, 1.0 / ior);
        // let refraction_in_ray = Ray(r.state.position, refraction_in_dir);
        // // let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_shape(r.state.scene.closest_shape_index));
        // let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_scene());
        // let refraction_in_r_t = raymarch(refraction_in_ray, RayMarchOptions_bg());

        let back_normal_inside = refraction.back_normal_inside;
        let back_normal = -back_normal_inside;
        // let refraction_out_incident_vec = normalize(refraction_in_r.state.position - refraction_in_ray.origin);
        // let refraction_out_dir = refract(refraction_out_incident_vec, back_normal, ior);
        // let refraction_out_ray = Ray(refraction_in_r.state.position, refraction_out_dir);
        // let refraction_out_r = raymarch(refraction_out_ray, RayMarchOptions_bg());

        // let rgb = vec3f(select(0, 1, is_hit(refraction_in_r)));

        // let tex_coord = 0.5 + 0.5 * refraction_out_r.state.position.xy;
        // let sample_coord = refraction_in_r_t.state.position.xy;
        // let tex_coord = 0.5 + 0.5 * sample_coord;
        // let sample = textureSample(t_diffuse, s_diffuse, tex_coord);

        var sample_r = rygcbv_r(textureSample(t_diffuse, s_diffuse, refraction_r.tex_coord).rgb);
        var sample_g = rygcbv_g(textureSample(t_diffuse, s_diffuse, refraction_g.tex_coord).rgb);
        var sample_b = rygcbv_b(textureSample(t_diffuse, s_diffuse, refraction_b.tex_coord).rgb);

        var sample_y = rygcbv_y(textureSample(t_diffuse, s_diffuse, refraction_r.tex_coord).rgb);
        var sample_c = rygcbv_c(textureSample(t_diffuse, s_diffuse, refraction_g.tex_coord).rgb);
        var sample_v = rygcbv_v(textureSample(t_diffuse, s_diffuse, refraction_b.tex_coord).rgb);

        var sample = rygcbv_rgb(sample_r, sample_y, sample_g, sample_c, sample_b, sample_v);
        // var sample = vec3f(sample_r, sample_g, sample_b);
        // var sample = textureSample(t_diffuse, s_diffuse, refraction.tex_coord);

        // let blur_px = 6;
        // let blur_factor = f32(1 + blur_px * 4);
        // for (var i = 1; i <= blur_px; i++) {
        //     let shift = px(f32(i));

        //     let b_sample_coord_x = sample_coord + vec2(shift, 0);
        //     let b_tex_coord_x = 0.5 + 0.5 * b_sample_coord_x;
        //     let b_sample_x = textureSample(t_diffuse, s_diffuse, b_tex_coord_x);

        //     let b_sample_coord_x2 = sample_coord - vec2(shift, 0);
        //     let b_tex_coord_x2 = 0.5 + 0.5 * b_sample_coord_x2;
        //     let b_sample_x2 = textureSample(t_diffuse, s_diffuse, b_tex_coord_x2);

        //     let b_sample_coord_y = sample_coord + vec2(0, shift);
        //     let b_tex_coord_y = 0.5 + 0.5 * b_sample_coord_y;
        //     let b_sample_y = textureSample(t_diffuse, s_diffuse, b_tex_coord_y);

        //     let b_sample_coord_y2 = sample_coord - vec2(0, shift);
        //     let b_tex_coord_y2 = 0.5 + 0.5 * b_sample_coord_y2;
        //     let b_sample_y2 = textureSample(t_diffuse, s_diffuse, b_tex_coord_y2);

        //     sample += b_sample_x + b_sample_x2 + b_sample_y + b_sample_y2;
        // }
        // sample /= blur_factor;

        let light_dir = normalize(light_pos - r.state.position);
        let diffuse_product = max(0.0, dot(r.normal, light_dir));

        let back_light_pos = vec3f(0, -32, -64);
        let back_light_dir = normalize(back_light_pos - r.state.position);
        let back_diffuse_product = max(0.0, dot(back_normal_inside, back_light_dir));

        let half_dir = normalize(view_dir + light_dir);
        let specular_coefficient = 2.0;
        let specular_product = max(0.0, dot(r.normal, half_dir));
        let specular_intensity = pow(specular_product, specular_coefficient);

        let back_half_dir = normalize(view_dir + back_light_dir);
        let back_specular_coefficient = 32.0;
        let back_specular_product = max(0.0, dot(back_normal, back_half_dir));
        let back_specular_intensity = pow(back_specular_product, back_specular_coefficient);

        let fr = fresnel(refraction_in_incident_vec, r.normal);

        let a = hit_alpha(r);
        let fr_i = (fr * 16) + (fr * ((specular_intensity * 64) + (back_specular_intensity * 32)));
        let rgb = (sample.rgb * 2) + (sample.rgb * ((diffuse_product * 2) + (back_diffuse_product * 1) + max(specular_intensity * 32, back_specular_intensity * 8) + fr_i));// + (vec3f(1) * (specular_intensity + fr));// + (vec3f(0.2) * fr);
        return vec4f(sqrt(rgb), a);
        // return vec4f(tex_coord, 0, a);
        // return vec4f(0.5 + 0.5 * refraction_out_dir, a);
        // return vec4f(rgb, a);
        // return vec4f(0.5 + 0.5 * r.normal, a);
    } else {
        discard;
        // return vec4f(0);
    }
    // return sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords / 2));
}


struct RefractionData {
    tex_coord: vec2f,
    back_normal_inside: vec3f,
}
fn refraction_tex_coord_normal(ray_position: vec3f, ray_origin: vec3f, normal: vec3f, ior: f32) -> RefractionData {
    let refraction_in_incident_vec = normalize(ray_position - ray_origin);
    let refraction_in_dir = refract(refraction_in_incident_vec, normal, ior);
    let refraction_in_ray = Ray(ray_position, refraction_in_dir);

    let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_scene());
    let refraction_in_r_t = raymarch(refraction_in_ray, RayMarchOptions_bg());

    let back_normal_inside = refraction_in_r.normal;

    let sample_coord = refraction_in_r_t.state.position.xy;
    let tex_coord = 0.5 + 0.5 * sample_coord;

    return RefractionData(tex_coord, back_normal_inside);
}

fn fresnel(eye_vector: vec3f, normal: vec3f) -> f32 {
    return pow(1.0 + dot(eye_vector, normal), 5.0);
}

@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(1) @binding(1)
var s_diffuse: sampler;
