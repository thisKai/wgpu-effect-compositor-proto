import super::util::{
    system::{viewport, viewport_cover_ratio, cursor, px},
    quad_vertex::{get_quad_vertex_sign, flip_y},
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
    scene::scene_silhouette_test,
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
    if !scene_silhouette_test(in.uv) {
        discard;
    }
    let view_dir = vec3f(0, 0, 1);
    let light_pos = vec3f(0, -16, -8);

    let ray = Ray(vec3f(in.uv, 0), vec3f(0, 0, 1));
    let r = raymarch(ray, RayMarchOptions_scene());
    if is_hit(r) && !hit_bg(r) {
    // if is_hit(r) {
        let ior = 1.5;
        let refraction_in_incident_vec = normalize(r.state.position - ray.origin);
        let refraction_in_dir = refract(refraction_in_incident_vec, r.normal, 1.0 / ior);
        let refraction_in_ray = Ray(r.state.position, refraction_in_dir);
        // let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_shape(r.state.scene.closest_shape_index));
        let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_scene());
        let refraction_in_r_t = raymarch(refraction_in_ray, RayMarchOptions_bg());

        let back_normal_inside = refraction_in_r.normal;
        let back_normal = -refraction_in_r.normal;
        // let refraction_out_incident_vec = normalize(refraction_in_r.state.position - refraction_in_ray.origin);
        // let refraction_out_dir = refract(refraction_out_incident_vec, back_normal, ior);
        // let refraction_out_ray = Ray(refraction_in_r.state.position, refraction_out_dir);
        // let refraction_out_r = raymarch(refraction_out_ray, RayMarchOptions_bg());

        // let rgb = vec3f(select(0, 1, is_hit(refraction_in_r)));

        // let tex_coord = 0.5 + 0.5 * refraction_out_r.state.position.xy;
        let sample_coord = refraction_in_r_t.state.position.xy;
        let tex_coord = 0.5 + 0.5 * sample_coord;
        // let sample = textureSample(t_diffuse, s_diffuse, tex_coord);
        var sample = textureSample(t_diffuse, s_diffuse, tex_coord);
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
        // return vec4f(0.5 + 0.5 * -refraction_in_r.normal, a);
    } else {
        discard;
        // return vec4f(0);
    }
    // return sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords / 2));
}


fn fresnel(eye_vector: vec3f, normal: vec3f) -> f32 {
    return pow(1.0 + dot(eye_vector, normal), 5.0);
}

@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(1) @binding(1)
var s_diffuse: sampler;
