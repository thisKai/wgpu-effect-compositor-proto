import super::util::{
    system::{viewport_cover_ratio, px},
    quad_vertex::{get_quad_vertex_sign, flip_y},
};
import super::shape::{
    storage::bindings::{shape_count, shape_appearance},
    sdf::{shape_query, ShapeQuery, blend::smin_blend},
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let vertex_sign = get_quad_vertex_sign(vertex_index);
    let vertex_pos = flip_y(vertex_sign * viewport_cover_ratio());

    out.position = vec4f(vertex_sign, 0, 1);
    out.frag_coord = vertex_pos;

    return out;
}

struct VertexOut {
    @builtin(position) position: vec4f,
    @location(0) frag_coord: vec2f,
}


@fragment
fn fs_main(in: VertexOut) -> FragmentOut {
    let blend_d = px(8);

    var d: f32 = 1.0;
    var rgba = vec4f(0);
    var frag_has_any_shape = false;

    var shape: ShapeQuery;

    for (var shape_id: u32 = 0; shape_id < shape_count(); shape_id++) {
        shape = shape_query(in.frag_coord, shape_id);

        let appearance = shape_appearance(shape_id);

        if frag_has_any_shape {
            let blend = smin_blend(d, shape.distance, blend_d);
            let scene_d = blend.x;
            let shape_blend = blend.y;

            d = scene_d;
            rgba = mix(rgba, appearance.tint_color, shape_blend);
        } else {
            frag_has_any_shape = true;
            d = shape.distance;
            rgba = appearance.tint_color;
        }
    }

    return FragmentOut(d, rgba);
}

struct FragmentOut {
    @location(0) sdf: f32,
    @location(1) tint_color: vec4f,
}
