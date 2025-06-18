import super::util::{
    system::{viewport, viewport_cover_ratio, cursor},
    quad_vertex::{get_quad_vertex_sign, flip_y, cover_ratio, fit_ratio},
    trig::{PI, TAU},
    sdf::{rect_sd, squircle_rect_sd, circle_sd},
    anti_alias::edge_step,
    ease::{ease_in_sine, ease_out_sine, ease_in_out_sine},
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
    let vertex_position = flip_y(vertex_sign) * local_aspect_ratio;
    let world_vertex_position = (half_size * vertex_sign) + center_rh_flip_y;
    let world_cursor_position = ((cursor.position / viewport.size * 2) - 1);
    let cursor_position = world_cursor_position - center_rh;
    let vertex_cursor_position = flip_y(world_cursor_position) - world_vertex_position;


    // let instance_aspect_ratio = cover_ratio(instance.half_size);
    // let world_vertex = instance.center + instance_vertex_sign * instance.half_size;
    // let world_vertex_aspect = flip_y(world_vertex * aspect_ratio);

    out.clip_position = vec4f(world_vertex_position, 0, 1);
    out.position = vertex_position;
    // out.world_position = world_vertex_aspect;
    out.center = center_rh * world_aspect_ratio;
    out.aspect_ratio = local_aspect_ratio;
    out.half_size = half_size * world_aspect_ratio;
    out.px = 1.0 / min(half_size_px.x, half_size_px.y);
    out.cursor_position = cursor_position;// * world_aspect_ratio * local_aspect_ratio;
    out.vertex_cursor_position = vertex_cursor_position;
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
    @location(8) cursor_position: vec2f,
    @location(9) vertex_cursor_position: vec2f,
}

struct FragmentIn {
    @location(0) position: vec2f,
    @location(1) world_position: vec2f,
    @location(3) center: vec2f,
    @location(4) aspect_ratio: vec2f,
    @location(5) half_size: vec2f,
    @location(6) px: f32,
    @location(7) tex_coords: vec2f,
    @location(8) cursor_position: vec2f,
    @location(9) vertex_cursor_position: vec2f,
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
    // let corner_r = 1.0;
    let corner_r = min(32.0 * in.px, 1);
    let shape_d = squircle_rect_sd(in.position, in.aspect_ratio, corner_r, 2);
    let edge = edge_step(shape_d, in.px);
    let light = smoothstep(-corner_r / 2, 0.0, shape_d) * 0.125;

    var rgb = sqrt(textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position, in))).rgb;

    let bevel = min(16.0 * in.px, 1) - in.px;
    // let bevel = 1.0;
    // let bevel = min(in.aspect_ratio.x, in.aspect_ratio.y);
    // let bevel = min(in.aspect_ratio.x, in.aspect_ratio.y);
    // let max_refraction_d = 64 * in.px;
    let max_refraction_d = bevel * 4;
    // let max_refraction_d = length(in.aspect_ratio / in.px) * in.px / 2;
    let hairline_width_px = 1.0;
    let hairline_reflection_d = 0.15;
    // if shape_d < 0.0 {
    let distance_per_pixel = 1 * in.px;
    let distance_px = -shape_d / distance_per_pixel;
    let hairline_coverage = smoothstep(hairline_width_px + 1.0, hairline_width_px - 0.75, distance_px);

    // let cursor_d = length(in.cursor_position) - 0.25;
    // let cursor_color = vec3f(1) * smoothstep(0, -0.01, cursor_d) * 2;
    let cursor_angle = atan2(in.cursor_position.y, in.cursor_position.x);
    let cursor_distance = max(length(in.cursor_position), 0.0);
    let cursor_light_position_xy = vec2f(cos(cursor_angle), sin(cursor_angle)) * 3.0;
    let cursor_light_position = (vec3f(in.cursor_position, 1));



    let reflection_dir = clamp(normalize(vec2f(dpdx(shape_d), dpdy(shape_d))), vec2f(-1), vec2f(1));
    let spec_bevel_r = 16 * in.px;
    let bevel_s = pow(smoothstep(0.0, -spec_bevel_r, shape_d), 1.0 / 16);
    let spec_bevel = pow(clamp(-shape_d - spec_bevel_r, 0, spec_bevel_r) / spec_bevel_r, 1.0);
    let z = pow(clamp(-shape_d - corner_r, 0, corner_r) / (corner_r * 32), 1.0);
    let reflection_percent = pow(clamp(1.0 + shape_d / (bevel / 1), 0, 1), 4);

    let n_xy = mix(reflection_dir, vec2f(0), bevel_s);
    let reflection_dir3 = normalize(vec3f(reflection_dir, bevel_s));
    let n = mix(reflection_dir3, vec3f(0, 0, 1), bevel_s);
    // let n = vec3f(mix(clamp(reflection_dir, vec2f(-1), vec2f(1)), vec2f(0), bevel_s), bevel_s);
    // let n = vec3f(mix(reflection_dir, vec2f(0), bevel_s), bevel_s);

    let view_dir = vec3f(0, 0, 1);
    // let light_dir = normalize(vec3f(0, -3, 3));
    let light_dir = normalize(cursor_light_position - n);
    let half_dir = normalize(view_dir + light_dir);

    let refraction_step = (smoothstep(-bevel, 0.0, shape_d));
    let refraction_dir = mix(vec2f(0), -reflection_dir, refraction_step);
    let refraction_coeff = length(in.aspect_ratio / in.px) * in.px;
    // let refraction_percent = pow(clamp(1.0 + shape_d / bevel, 0, 1), 2);

    let refraction_percent = 1.0;
    // let refraction_percent = pow(smoothstep(-bevel, 0.0, shape_d), 1);
    let offset = max_refraction_d * refraction_percent * refraction_dir;

    let diffuse_product = max(0.0, dot(n, light_dir));
    let diffuse_intensity = (diffuse_product * 1 * 5) + 1;
    // let diffuse_intensity = 1.0;

    let specular_coefficient = 128.0;
    let specular_product = max(0.0, dot(n, half_dir));
    let specular_intensity = pow(specular_product, specular_coefficient);

    let blurred_sample = blur(in.position + offset, in, 4).rgb;
    // let blurred_sample = textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position + offset, in)).rgb;
    // let coverage = smoothstep(-0.75, 1.65, distance_px);
    rgb = mix(rgb, blurred_sample * 2, 1);

    // let hairline_coverage = smoothstep(0.0, 1.0, distance_px) * (1.0 - smoothstep(hairline_width_px, hairline_width_px + 1, distance_px));

    let outer_reflection_sample_coord = in.position - hairline_reflection_d * refraction_dir;
    let outer_reflection_sample = blur(outer_reflection_sample_coord, in, 4).rgb;
    // let outer_reflection_sample = textureSample(t_diffuse, s_diffuse, inst_tex_coord(outer_reflection_sample_coord, in)).rgb;

    rgb += hairline_coverage * outer_reflection_sample * 4;
    rgb += outer_reflection_sample;
    // rgb += vec3f(1) * ((diffuse_product / 4) + (specular_intensity * 128));
    // rgb += edge_glow(in.position + offset, in, shape_d) * (diffuse_product + specular_intensity);
    // rgb += pow(point_glow(offset, in, shape_d), vec3f(1));
    // }



    // let glass_sample = sqrt(textureSample(t_diffuse, s_diffuse, inst_tex_coord(in.position, in)));

    // let rgb = mix(sample.rgb * 0.8, 0.2 + glass_sample.rgb * 0.7, d);
    // return vec4f(vec3f(specular_intensity), 1);
    return vec4f(sqrt(rgb * edge), edge);
    // return glass_sample;
    // return vec4f((0.5 + 0.5 * n), 1.0);
    // return vec4f(1);
}

fn edge_glow(inst_coord: vec2f, in: FragmentIn, shape_d: f32) -> vec3f {
    let rgb = vec3f(0x33, 0x99, 0xFF) / 255;
    let white = vec3f(1);
    let glow_radius = 8 * in.px;

    let intensity = smoothstep(-glow_radius, 0, shape_d);
    let outer_intensity = pow(intensity, 32) / 2;
    let inner_intensity = pow(intensity, 256) / 2;
    return (rgb * outer_intensity) + (white * inner_intensity);
}
fn point_glow(offset: vec2f, in: FragmentIn, shape_d: f32) -> vec3f {
    let rgb = vec3f(0x33, 0x99, 0xFF) / 255;
    let white = vec3f(1);

    let glow_d = length(in.vertex_cursor_position + offset);

    let intensity = smoothstep(1.0, 0, glow_d);
    let outer_intensity = pow(intensity, 4) / 2;
    let inner_intensity = pow(intensity, 128) / 2;
    return (rgb * outer_intensity) + (white * inner_intensity);
}

fn blur(inst_coord: vec2f, in: FragmentIn, radius: f32) -> vec4f {
    var total = vec4f(0);
    var count = 0;

    for (var y = -4; y <= 4; y++) {
        for (var x = -4; x <= 4; x++) {
            let offset = vec2f(f32(x), f32(y));
            // let weight = pow(length(1.0 - (offset / 4)), 4);
            total += textureSample(t_diffuse, s_diffuse, inst_tex_coord(inst_coord + offset * in.px * radius, in)) ;
            count ++;
        }
    }

    return total / f32(count);
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
