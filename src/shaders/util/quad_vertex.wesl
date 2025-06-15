fn get_quad_vertex_sign(vertex_index: u32) -> vec2f {
    let position_index = QUAD_VERTEX_SIGN_INDEX[vertex_index];
    return QUAD_VERTEX_SIGN[position_index];
}
fn flip_y(p: vec2f) -> vec2f {
    return p * FLIP_Y;
}

const FLIP_Y = vec2f(1, -1);

const QUAD_VERTEX_SIGN = array<vec2f, 4>(
    vec2f(-1, -1),
    vec2f(-1, 1),
    vec2f(1, 1),
    vec2f(1, -1),
);
const QUAD_VERTEX_SIGN_INDEX = array<u32, 6>(0, 1, 2, 2, 3, 0);
