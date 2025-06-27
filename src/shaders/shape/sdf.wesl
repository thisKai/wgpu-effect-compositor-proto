import super::{
    kind::CIRCLE,
    storage::bindings::{
        shape_kind,
        shape_location,
        ShapeLocation,
        shape_appearance,
        get_circle,
    },
};
import self::{
    exact::circle_sd,
};

fn shape_query(p: vec2f, shape_id: u32) -> ShapeQuery {
    let shape = shape_location(shape_id);
    var kind = shape.map.kind;

    var distance: f32;

    switch kind {
        case CIRCLE {
            let circle = get_circle(shape.map.kind_index);
            distance = circle_sd(p - shape.position.center, circle.radius);
        }
        default {
            kind = 0;
            distance = 0.0;
        }
    }

    return ShapeQuery(shape, distance);
}
struct ShapeQuery {
    location: ShapeLocation,
    distance: f32,
}

// fn shape_sd(p: vec2f, shape_id: u32) -> ShapeSD {
//     var kind = shape_kind(shape_id);
//     var distance: f32;
//     var rgba: vec4f;

//     switch kind {
//         case CIRCLE {
//             let circle = get_circle(shape_id);
//             distance = circle_sd(p - circle.center, circle.radius);
//             rgba = circle.appearance.tint_color;
//         }
//         default {
//             kind = 0;
//             distance = 0.0;
//             rgba = vec4f(0);
//         }
//     }

//     return ShapeQuery(kind, distance, rgba);
// }

// struct ShapeSD {
//     kind: u32,
//     distance: f32,
//     rgba: vec4f,
// }
