import super::util::quad_vertex::get_quad_vertex_sign;

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let instance_vertex_sign = get_quad_vertex_sign(vertex_index);

    out.clip_position = vec4f(instance_vertex_sign, 0, 1);

    return out;
}

struct VertexOut {
    @builtin(position) clip_position: vec4<f32>,
}

@fragment
fn fs_main(in: FragmentIn) -> @location(0) vec4f {
    return vec4f(1);
}

struct FragmentIn {
    @builtin(position) viewport_position: vec4<f32>,
}
