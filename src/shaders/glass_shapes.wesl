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
        shape_query,
        ShapeQuery,
        anti_alias::edge_alpha,
        blend::{smin, smin_blend},
        exact::circle_sd,
    },
    raymarching::raymarch_shape_layer_extrusion_downwards,
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let vertex_sign = get_quad_vertex_sign(vertex_index);
    let vertex_pos = flip_y(vertex_sign * viewport_cover_ratio());
    let texture_coord = 0.5 + 0.5 * flip_y(vertex_sign);

    out.position = vec4f(vertex_sign, 0, 1);
    out.uv = vertex_pos;
    out.texture_coord = texture_coord;

    return out;
}

struct VertexOut {
    @builtin(position) position: vec4f,
    @location(0) uv: vec2f,
    @location(1) texture_coord: vec2f,
}


@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4f {
    let d = textureSample(sdf_texture, sdf_sampler, in.texture_coord).r;
    let a = edge_alpha(d);

    let tint_color = textureSample(tint_color_texture, tint_color_sampler, in.texture_coord);

    return vec4f(sqrt(tint_color.rgb), tint_color.a * a);
}


@group(3) @binding(0)
var sdf_texture: texture_2d<f32>;
@group(3) @binding(1)
var sdf_sampler: sampler;

@group(3) @binding(2)
var tint_color_texture: texture_2d<f32>;
@group(3) @binding(3)
var tint_color_sampler: sampler;
