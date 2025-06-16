import super::util::{
    system::{viewport, viewport_cover_ratio},
    quad_vertex::{get_quad_vertex_sign, flip_y, cover_ratio, fit_ratio},
    trig::{PI, TAU},
    sdf::{rect_sd, squircle_rect_sd},
    anti_alias::edge_step,
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32, instance: GlassBox) -> VertexOut {
    var out: VertexOut;

    let world_aspect_ratio = viewport_cover_ratio();

    let vertex_sign = get_quad_vertex_sign(vertex_index);

    let half_size_px = instance.size_px / 2;
    let center_px = instance.position_px + half_size_px;

    let half_size = instance.size_px / viewport.size;
    let center_lh = center_px / viewport.size;
    let center_rh = (center_lh * 2) - 1;
    let center_rh_flip_y = flip_y(center_rh);

    let local_aspect_ratio = fit_ratio(half_size_px);
    let local_position = flip_y(vertex_sign) * local_aspect_ratio;
    let clip_position = (half_size * vertex_sign) + center_rh_flip_y;


    // let instance_aspect_ratio = cover_ratio(instance.half_size);
    // let world_vertex = instance.center + instance_vertex_sign * instance.half_size;
    // let world_vertex_aspect = flip_y(world_vertex * aspect_ratio);

    out.clip_position = vec4f(clip_position, 0, 1);
    out.position = local_position;
    // out.world_position = world_vertex_aspect;
    out.center = center_rh * world_aspect_ratio;
    out.aspect_ratio = local_aspect_ratio;
    out.half_size = half_size * world_aspect_ratio;
    out.px = 2.0 / instance.size_px.x;
    // out.tex_coords = 0.5 + 0.5 * world_vertex_aspect;

    return out;
}

struct GlassBox {
    @location(0) position_px: vec2f,
    @location(1) size_px: vec2f,
}

struct VertexOut {
    @builtin(position) clip_position: vec4f,
    @location(0) position: vec2f,
    @location(1) world_position: vec2f,
    @location(3) center: vec2f,
    @location(4) aspect_ratio: vec2f,
    @location(5) half_size: vec2f,
    @location(6) px: f32,
    @location(7) tex_coords: vec2f,
}

struct FragmentIn {
    @location(0) position: vec2f,
    @location(1) world_position: vec2f,
    @location(3) center: vec2f,
    @location(4) aspect_ratio: vec2f,
    @location(5) half_size: vec2f,
    @location(6) px: f32,
    @location(7) tex_coords: vec2f,
}

@fragment
fn fs_main(@builtin(position) viewport_position: vec4<f32>, in: FragmentIn) -> @location(0) vec4f {
    let world_px = 1.0 / viewport.size.x;

    // let sample = sqrt(textureSample(t_diffuse, s_diffuse, in.tex_coords));

    // let st = (viewport_position.xy - 0.5 * viewport.size) / viewport.size.y;
    // let m = (viewport_position.xy - 0.5 * viewport.size) / viewport.size.y;

    // let box = rect_sd(st - m, (in.half_size - 0.25));
    // // let box = rect_sd(in.world_position - in.center, (in.half_size - 0.25));
    // let box_shape = smoothstep(1.5 * world_px, -0.5 * world_px, (box - 0.25));
    // let box_disp = smoothstep(0.35, 0.0, (box - 0.25));
    // let box_light = box_shape * smoothstep(0.0, 0.3, (box - 0.4));

    // var uv = viewport_position.xy / viewport.size;
    // uv -= 0.5;

    // let t_c_step = smoothstep(0.5, 1.0, box_disp);

    // uv *= 0.5 + 0.5 * t_c_step;
    // uv += 0.5;

    // // let glass_sample0 = sqrt(glass(uv, 10.0, 10.0, 0.5));

    // let angle = atan2(in.position.y, in.position.x);
    // let r = length(in.position);

    // let a_shift = PI / 4;
    // let angle1 = angle - a_shift;
    // let angle2 = angle + a_shift;

    // let pos_1 = vec2f(cos(angle1), sin(angle1)) * r;
    // let pos_2 = vec2f(cos(angle2), sin(angle2)) * r;

    // let w_pos = (in.position * in.half_size) + in.center;
    // let w_pos1 = (pos_1 * in.half_size) + in.center;
    // let w_pos2 = (pos_2 * in.half_size) + in.center;

    // let tex_coord = 0.5 + 0.5 * w_pos;
    // let tex_coord_1 = 0.5 + 0.5 * w_pos1;
    // let tex_coord_2 = 0.5 + 0.5 * w_pos2;


    let glass_sample = sqrt(glass(in, 20.0, 20.0));
    let corner_r = 64.0 * in.px;
    let shape_d = squircle_rect_sd(in.position, in.aspect_ratio, corner_r, 3);
    let edge = edge_step(shape_d, in.px);
    let light = smoothstep(-corner_r / 2, 0.0, shape_d) * 0.125;

    var rgb = sqrt(textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position, in))).rgb;

    let bevel = corner_r;
    let max_refraction_d = 0.8;
    let hairline_width_px = 1.5;
    let hairline_reflection_d = corner_r * 2;
    // if shape_d < 0.0 {
    let distance_per_pixel = 1 * in.px;
    let distance_px = -shape_d / distance_per_pixel;

    let refraction_dir = -normalize(vec2f(dpdx(shape_d), dpdy(shape_d)));
    let refraction_percent = pow(clamp(1.0 + shape_d / bevel, 0, 1), 4);
    let offset = max_refraction_d * refraction_percent * refraction_dir;

    let blurred_sample = textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position + offset, in)).rgb;
    let coverage = smoothstep(0.0, 1.0, distance_px);
    rgb = mix(rgb, blurred_sample * 4, coverage);

    let hairline_coverage = smoothstep(0.0, 1.0, distance_px) * (1.0 - smoothstep(hairline_width_px, hairline_width_px + 1, distance_px));
    let outer_reflection_sample_coord = in.position - hairline_reflection_d * refraction_dir;
    let outer_reflection_sample = textureSample(t_diffuse, s_diffuse, inst_tex_coord(outer_reflection_sample_coord, in)).rgb;

    rgb += hairline_coverage * outer_reflection_sample * 2;
    // }



    // let glass_sample = sqrt(textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position, in)));

    // let rgb = mix(sample.rgb * 0.8, 0.2 + glass_sample.rgb * 0.7, d);
    return vec4f(sqrt(rgb), edge);
    // return glass_sample;
    // return vec4f((0.5 + 0.5 * in.position), 1.0, 1.0);
    // return vec4f(1);
}

fn inst_tex_coord(inst_coord: vec2f, in: FragmentIn) -> vec2f {
    let w_pos = ((inst_coord / fit_ratio(in.half_size)) * in.half_size) + in.center;
    let tex_coord = 0.5 + 0.5 * (w_pos);
    return tex_coord;
}

fn glass(in: FragmentIn, direction: f32, quality: f32) -> vec4f {
    let angle = atan2(in.position.y, in.position.x);
    let r = length(in.position);

    // var color = textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position, in));
    var color = vec4f(0);

    for (var d = 0.0; d < PI; d += PI / direction) {
        for (var i = 1.0 / quality; i <= 1.0; i += 1.0 / quality) {
            let shift = d * i;
            // let angle_l = angle - shift;
            // let angle_g = angle + shift;

            // let angle_i = angle + d * i;
            // let circle = vec2f(cos(angle_i), sin(angle_i));
            // let sample_coord = inst_tex_coord(circle * r, in);

            let sample_l = angle_coord(angle - shift, r, in);
            let sample_g = angle_coord(angle + shift, r, in);
            color += textureSample(t_diffuse, s_diffuse, sample_l);
            color += textureSample(t_diffuse, s_diffuse, sample_g);
        }
    }

    color /= quality * direction * 2;
    return color;
}
fn angle_coord(angle: f32, r: f32, in: FragmentIn) -> vec2f {
    let circle = vec2f(cos(angle), sin(angle));
    return inst_tex_coord(circle * r, in);
}

fn glass0(p: vec2f, direction: f32, quality: f32, size: f32) -> vec4f {
    let radius = size;
    var color = textureSample(t_diffuse, s_diffuse, p);

    for (var d = 0.0; d < PI; d += PI / direction) {
        for (var i = 1.0 / quality; i <= 1.0; i += 1.0 / quality) {
            let shift = vec2f(cos(d), sin(d));
            color += textureSample(t_diffuse, s_diffuse, (p + shift) * radius * i);
        }
    }

    color /= quality * direction;
    return color;
}


@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(1) @binding(1)
var s_diffuse: sampler;
