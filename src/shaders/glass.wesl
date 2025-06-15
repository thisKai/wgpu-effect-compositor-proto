import super::util::quad_vertex::{get_quad_vertex_sign, flip_y};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let instance_vertex_sign = get_quad_vertex_sign(vertex_index);

    out.clip_position = vec4f(instance_vertex_sign, 0, 1);
    out.tex_coords = 0.5 + 0.5 * flip_y(instance_vertex_sign);

    return out;
}

struct VertexOut {
    @builtin(position) clip_position: vec4f,
    @location(0) tex_coords: vec2f
}

@fragment
fn fs_main(in: FragmentIn) -> @location(0) vec4f {
    return sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords));
}

struct FragmentIn {
    @builtin(position) viewport_position: vec4<f32>,
    @location(0) tex_coords: vec2f
}

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0) @binding(1)
var s_diffuse: sampler;
