import super::util::{
    system::{viewport, viewport_cover_ratio, cursor},
    quad_vertex::{get_quad_vertex_sign, flip_y},
    ratio::{size_range, min2},
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let instance_vertex_sign = get_quad_vertex_sign(vertex_index);

    out.clip_position = vec4f(instance_vertex_sign, 0, 1);
    out.texture_coord = 0.5 + 0.5 * flip_y(instance_vertex_sign * viewport_cover_ratio());

    return out;
}

struct VertexOut {
    @builtin(position) clip_position: vec4f,
    @location(0) texture_coord: vec2f
}

@fragment
fn fs_main(in: FragmentIn) -> @location(0) vec4f {
    return sqrt(textureSample(wallpaper_texture, wallpaper_sampler, in.texture_coord));
}

struct FragmentIn {
    @builtin(position) viewport_position: vec4<f32>,
    @location(0) texture_coord: vec2f
}

@group(1) @binding(0)
var wallpaper_texture: texture_2d<f32>;
@group(1) @binding(1)
var wallpaper_sampler: sampler;
