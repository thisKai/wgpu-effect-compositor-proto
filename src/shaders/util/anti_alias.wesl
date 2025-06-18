import super::system::px;

fn edge_alpha(d: f32) -> f32 {
    return smoothstep(px(ANTI_ALIAS_D_OUTER_PX), px(ANTI_ALIAS_D_INNER_PX), d);
}

fn edge_step(d: f32, px: f32) -> f32 {
    let edge_inner = ANTI_ALIAS_D_INNER_PX * px;
    let edge_outer = ANTI_ALIAS_D_OUTER_PX * px;

    return smoothstep(edge_outer, edge_inner, d);
}

const ANTI_ALIAS_D_INNER_PX = -0.65;
const ANTI_ALIAS_D_OUTER_PX = 0.75;
