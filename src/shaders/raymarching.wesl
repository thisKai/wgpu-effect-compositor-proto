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
        RayMarchOptions_inside_shape,
    },
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
    let ray = Ray(vec3f(in.uv, 0), vec3f(0, 0, 1));
    let r = raymarch(ray, RayMarchOptions_scene());
    if is_hit(r) && !hit_bg(r) {
    // if is_hit(r) {
        let ior = 1.5;
        let refraction_in_incident_vec = normalize(r.state.position - ray.origin);
        let refraction_in_dir = refract(refraction_in_incident_vec, r.normal, 1.0 / ior);
        let refraction_in_ray = Ray(r.state.position + (refraction_in_dir * px(1)), refraction_in_dir);
        // let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_inside_shape(r.state.scene.closest_shape_index));
        let refraction_in_r = raymarch(refraction_in_ray, RayMarchOptions_bg());

        // let refraction_out_incident_vec = normalize(refraction_in_r.state.position - refraction_in_ray.origin);
        // let refraction_out_dir = refract(refraction_out_incident_vec, refraction_in_r.normal, ior);
        // let refraction_out_ray = Ray(refraction_in_r.state.position + (refraction_out_dir * px(1)), refraction_out_dir);
        // let refraction_out_r = raymarch(refraction_out_ray, RayMarchOptions_scene());

        // let rgb = vec3f(select(0, 1, is_hit(refraction_in_r)));

        let tex_coord = 0.5 + 0.5 * refraction_in_r.state.position.xy;
        let sample = textureSample(t_diffuse, s_diffuse, tex_coord);

        let a = hit_alpha(r);
        return vec4f(sqrt(sample.rgb), a);
        // return vec4f(0.5 + 0.5 * refraction_in_dir, a);
        // return vec4f(rgb, a);
        // return vec4f(0.5 + 0.5 * refraction_in_r.normal, a);
    } else {
        discard;
        // return vec4f(0);
    }
    // return sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords / 2));
}

@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(1) @binding(1)
var s_diffuse: sampler;
