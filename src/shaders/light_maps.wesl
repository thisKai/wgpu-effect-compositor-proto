import super::util::quad_vertex::{get_quad_vertex_sign, flip_y};
import super::shape::{
    sdf::anti_alias::edge_alpha,
    raymarching::{
        ray::frag_ray_down,
        march::RAYMARCH_HIT,
        scene::{
            ray_march,
            compute_normal,
            scene_silhouette_sd_sample,
        },
    },
};


@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
    var out: VertexOut;

    let vertex_sign = get_quad_vertex_sign(vertex_index);
    let vertex_pos = flip_y(vertex_sign);
    let texture_coord = 0.5 + 0.5 * flip_y(vertex_sign);

    out.position = vec4f(vertex_sign, 0, 1);
    out.frag_coord = vertex_pos;
    out.texture_coord = texture_coord;

    return out;
}

struct VertexOut {
    @builtin(position) position: vec4f,
    @location(0) frag_coord: vec2f,
    @location(1) texture_coord: vec2f,
}


@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4f {
    let silhouette_d = scene_silhouette_sd_sample(in.texture_coord);
    let alpha = edge_alpha(silhouette_d);

    if alpha <= 0 {
        discard;
    }

    var frag_ray = frag_ray_down(in.frag_coord);
    var result = ray_march(&frag_ray);

    if result == RAYMARCH_HIT {
        let normal = compute_normal(frag_ray.state.position);
        let surface_z = frag_ray.state.position.z;

        return vec4f(0.5 + 0.5 * normal, surface_z);
    }

    return vec4f(0.5, 0.5, -1, 1);
}
