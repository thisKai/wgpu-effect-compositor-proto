import super::util::{
    system::{viewport, viewport_cover_ratio, cursor},
    quad_vertex::{get_quad_vertex_sign, flip_y},
};
import super::util::raymarch::{
    ray::Ray,
    march::{raymarch, is_hit, hit_alpha},
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
    let r = raymarch(ray);
    if is_hit(r) {
        let a = hit_alpha(r);
        return vec4f(vec3f(1), a);
    } else {
        return vec4f(0);
    }
    // return sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords / 2));
}

@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(1) @binding(1)
var s_diffuse: sampler;
