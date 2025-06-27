import package::util::system::px;

fn edge_alpha(d: f32) -> f32 {
    return smoothstep(px(ANTI_ALIAS_D_OUTER_PX), px(ANTI_ALIAS_D_INNER_PX), d);
}

const ANTI_ALIAS_D_INNER_PX = -0.65;
const ANTI_ALIAS_D_OUTER_PX = 0.75;
