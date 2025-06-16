import super::util::{
    system::{viewport, viewport_cover_ratio, viewport_fit_ratio, cursor},
    quad_vertex::{get_quad_vertex_sign, flip_y},
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let instance_vertex_sign = get_quad_vertex_sign(vertex_index);

    out.clip_position = vec4f(instance_vertex_sign, 0, 1);
    out.tex_coords = 0.5 + 0.5 * flip_y(instance_vertex_sign * viewport_cover_ratio());

    return out;
}

struct VertexOut {
    @builtin(position) clip_position: vec4f,
    @location(0) tex_coords: vec2f
}

@fragment
fn fs_main(in: FragmentIn) -> @location(0) vec4f {
    let uv = (in.viewport_position.xy / viewport.size * 2)-1;
    let cursor_uv = (cursor.position / viewport.size * 2) - 1;
    let cursor_d = distance(uv, cursor_uv)-0.5;
    let cursor_color = vec3f(1) * smoothstep(0, -1, cursor_d);
    return sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords) + vec4f(cursor_color, 0.5));
}

struct FragmentIn {
    @builtin(position) viewport_position: vec4<f32>,
    @location(0) tex_coords: vec2f
}

@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(1) @binding(1)
var s_diffuse: sampler;
