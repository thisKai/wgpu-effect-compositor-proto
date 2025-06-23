use std::{array, mem};

use wesl::include_wesl;
use wgpu::util::DeviceExt;

use super::{
    pointer::{PointerHit, PointerState},
    system::SystemGroup,
    wallpaper::Wallpaper,
};

pub struct Raymarching {
    shapes: Shapes,
    state: PointerState,
    shapes_buffers: ShapesBuffers,
    pipeline: wgpu::RenderPipeline,
}
impl Raymarching {
    pub fn draw(
        &self,
        render_pass: &mut wgpu::RenderPass,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) {
        render_pass.set_pipeline(&self.pipeline);
        render_pass.set_bind_group(0, &system.bind_group, &[]);
        render_pass.set_bind_group(1, &wallpaper.texture.bind_group, &[]);
        render_pass.set_bind_group(2, &self.shapes_buffers.bind_group, &[]);
        render_pass.draw(0..6, 0..1);
    }

    pub fn cursor_move(&mut self, queue: &wgpu::Queue, x: f64, y: f64) {
        let next_state = match self.state.take() {
            PointerState::Idle => {
                let hit = self.shapes.find_hovered(x, y);
                hit.map(|h| PointerState::Hovered {
                    index: h.index,
                    hover_position: h.local_position,
                })
                .unwrap_or_default()
            }
            PointerState::Hovered { index, .. } => {
                let hit = self.shapes.check_hovered(index, x, y);
                match hit {
                    Some(hit) => PointerState::Hovered {
                        index,
                        hover_position: hit,
                    },
                    None => {
                        let hit = self.shapes.find_hovered(x, y);
                        hit.map(|h| PointerState::Hovered {
                            index: h.index,
                            hover_position: h.local_position,
                        })
                        .unwrap_or_default()
                    }
                }
            }
            PointerState::Pressed {
                index,
                press_position,
            } => PointerState::Dragging {
                index,
                press_position,
            },
            PointerState::Dragging {
                index,
                press_position,
            } => {
                self.shapes.shapes[index].drag_move(press_position, [x as f32, y as f32]);
                let shapes_data = self.shapes.buffer_data();

                queue.write_buffer(
                    &self.shapes_buffers.shapes,
                    0,
                    bytemuck::cast_slice(&shapes_data.shapes),
                );
                queue.write_buffer(
                    &self.shapes_buffers.spheres,
                    0,
                    bytemuck::cast_slice(&shapes_data.spheres),
                );
                queue.write_buffer(
                    &self.shapes_buffers.rounded_boxes,
                    0,
                    bytemuck::cast_slice(&shapes_data.rounded_boxes),
                );

                PointerState::Dragging {
                    index,
                    press_position,
                }
            }
        };
        self.state = next_state;
    }
    pub fn mouse_press(&mut self, queue: &wgpu::Queue) {
        let next_state = match self.state.take() {
            PointerState::Idle => PointerState::Idle,
            PointerState::Hovered {
                index,
                hover_position,
            } => PointerState::Pressed {
                index,
                press_position: hover_position,
            },
            PointerState::Pressed {
                index,
                press_position,
            } => todo!(),
            PointerState::Dragging {
                index,
                press_position,
            } => todo!(),
        };
        self.state = next_state;
    }
    pub fn mouse_release(&mut self, queue: &wgpu::Queue) {
        let next_state = match self.state.take() {
            PointerState::Idle => PointerState::Idle,
            PointerState::Hovered {
                index,
                hover_position,
            } => todo!(),
            PointerState::Pressed {
                index,
                press_position,
            } => PointerState::Hovered {
                index,
                hover_position: press_position,
            },
            PointerState::Dragging {
                index,
                press_position,
            } => PointerState::Hovered {
                index,
                hover_position: press_position,
            },
        };
        self.state = next_state;
    }
    pub fn new(
        device: &wgpu::Device,
        config: &wgpu::SurfaceConfiguration,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) -> Self {
        let shapes = Shapes::new(vec![
            Shape::Sphere(Sphere {
                center: [100.0, 100.0, 64.0],
                radius: 48.0,
            }),
            Shape::Sphere(Sphere {
                center: [500.0, 500.0, 64.0],
                radius: 48.0,
            }),
            Shape::RoundedBox(RoundedBox {
                center: [250.0, 250.0, 64.0],
                half_size: [200.0, 100.0, 48.0],
                radius: 48.0,
                ..Default::default()
            }),
            Shape::RoundedBox(RoundedBox {
                center: [250.0, 50.0, 64.0],
                half_size: [48.0, 48.0, 48.0],
                radius: 48.0,
                ..Default::default()
            }),
        ]);
        let shapes_buffers = ShapesBuffers::new(&shapes, device);

        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("raymarching shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("raymarching").into()),
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("raymarching render pipeline layout"),
            bind_group_layouts: &[
                &system.bind_group_layout,
                &wallpaper.texture.bind_group_layout,
                &shapes_buffers.bind_group_layout,
            ],
            push_constant_ranges: &[],
        });

        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("raymarching render pipeline"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format: config.format,
                    blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            }),
            primitive: wgpu::PrimitiveState {
                topology: wgpu::PrimitiveTopology::TriangleList,
                strip_index_format: None,
                front_face: wgpu::FrontFace::Cw,
                cull_mode: None, //Some(wgpu::Face::Back),
                // Setting this to anything other than Fill requires Features::NON_FILL_POLYGON_MODE
                polygon_mode: wgpu::PolygonMode::Fill,
                // Requires Features::DEPTH_CLIP_CONTROL
                unclipped_depth: false,
                // Requires Features::CONSERVATIVE_RASTERIZATION
                conservative: false,
            },
            depth_stencil: None,
            multisample: wgpu::MultisampleState {
                count: 1,
                mask: !0,
                alpha_to_coverage_enabled: false,
            },
            multiview: None,
            cache: None,
        });

        Self {
            pipeline,
            shapes,
            shapes_buffers,
            state: Default::default(),
        }
    }
}

struct ShapesBuffers {
    shapes: wgpu::Buffer,
    spheres: wgpu::Buffer,
    rounded_boxes: wgpu::Buffer,
    pub bind_group_layout: wgpu::BindGroupLayout,
    pub bind_group: wgpu::BindGroup,
}
impl ShapesBuffers {
    fn new(shapes: &Shapes, device: &wgpu::Device) -> Self {
        let data = shapes.buffer_data();

        let shapes = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("shapes buffer"),
            contents: bytemuck::cast_slice(&data.shapes),
            usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        });
        let spheres = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("spheres buffer"),
            contents: bytemuck::cast_slice(&data.spheres),
            usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        });
        let rounded_boxes = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("rounded boxes buffer"),
            contents: bytemuck::cast_slice(&data.rounded_boxes),
            usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        });

        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Storage { read_only: true },
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Storage { read_only: true },
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 2,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Storage { read_only: true },
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
            ],
            label: Some("shapes bind group layout"),
        });
        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: shapes.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: spheres.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: rounded_boxes.as_entire_binding(),
                },
            ],
            label: Some("shapes bind group"),
        });

        Self {
            shapes,
            spheres,
            rounded_boxes,
            bind_group_layout,
            bind_group,
        }
    }
}

struct Shapes {
    shapes: Vec<Shape>,
}
impl Shapes {
    fn new(shapes: Vec<Shape>) -> Self {
        Self { shapes }
    }
    pub fn check_hovered(&self, shape: usize, x: f64, y: f64) -> Option<[f32; 2]> {
        let [x, y] = [x as f32, y as f32];
        let b = self.shapes[shape].bounding_box();
        b.hit_test(x, y).then(|| b.local_point(x, y))
    }
    pub fn find_hovered(&self, x: f64, y: f64) -> Option<PointerHit> {
        let [x, y] = [x as f32, y as f32];
        self.shapes.iter().enumerate().find_map(|(i, s)| {
            let b = s.bounding_box();

            Some(PointerHit {
                index: i,
                local_position: b.hit_test(x, y).then(|| b.local_point(x, y))?,
            })
        })
    }
    fn buffer_data(&self) -> ShapesData {
        let mut shapes = Vec::new();
        let mut spheres = Vec::new();
        let mut rounded_boxes = Vec::new();

        for shape in &self.shapes {
            match shape {
                Shape::Sphere(sphere) => {
                    let sphere_index = spheres.len();
                    spheres.push(*sphere);

                    let shape = ShapeId {
                        kind: ShapeKind::Sphere as _,
                        kind_index: sphere_index as _,
                    };
                    shapes.push(shape);
                }
                Shape::RoundedBox(rounded_box) => {
                    let rounded_box_index = rounded_boxes.len();
                    rounded_boxes.push(*rounded_box);

                    let shape = ShapeId {
                        kind: ShapeKind::RoundedBox as _,
                        kind_index: rounded_box_index as _,
                    };
                    shapes.push(shape);
                }
            }
        }

        ShapesData {
            shapes,
            spheres,
            rounded_boxes,
        }
    }
}
struct ShapesData {
    shapes: Vec<ShapeId>,
    spheres: Vec<Sphere>,
    rounded_boxes: Vec<RoundedBox>,
}

enum Shape {
    Sphere(Sphere),
    RoundedBox(RoundedBox),
}
impl Shape {
    fn bounding_box(&self) -> AABB {
        match self {
            Shape::Sphere(sphere) => sphere.bounding_box(),
            Shape::RoundedBox(rounded_box) => rounded_box.bounding_box(),
        }
    }
    fn drag_move(&mut self, press_position: [f32; 2], cursor_position: [f32; 2]) {
        match self {
            Shape::Sphere(sphere) => sphere.drag_move(press_position, cursor_position),
            Shape::RoundedBox(rounded_box) => {
                rounded_box.drag_move(press_position, cursor_position)
            }
        }
    }
}

#[repr(u32)]
enum ShapeKind {
    None,
    Sphere,
    RoundedBox,
}

#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
struct ShapeId {
    kind: u32,
    kind_index: u32,
}

#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
struct Sphere {
    center: [f32; 3],
    radius: f32,
}
impl Sphere {
    fn bounding_box(&self) -> AABB {
        let [x, y, _] = self.center;
        let center = [x, y];
        let min = center.map(|d| d - self.radius);
        let max = center.map(|d| d + self.radius);

        AABB { min, max }
    }
    fn drag_move(&mut self, press_position: [f32; 2], cursor_position: [f32; 2]) {
        let [x, y] = cursor_position;
        let [press_x, press_y] = press_position;
        let new_pos = [x - press_x, y - press_y].map(|d| d.round());
        let [center_x, center_y] = new_pos.map(|d| d + self.radius);
        let [_, _, center_z] = self.center;
        self.center = [center_x, center_y, center_z];
    }
}

#[repr(C)]
#[derive(Default, Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
struct RoundedBox {
    center: [f32; 3],
    _padding: u32,
    half_size: [f32; 3],
    radius: f32,
    // _padding2: u32,
}
impl RoundedBox {
    fn bounding_box(&self) -> AABB {
        let min = array::from_fn(|i| self.center[i] - self.half_size[i]);
        let max = array::from_fn(|i| self.center[i] + self.half_size[i]);

        AABB { min, max }
    }
    fn drag_move(&mut self, press_position: [f32; 2], cursor_position: [f32; 2]) {
        let [x, y] = cursor_position;
        let [press_x, press_y] = press_position;
        let new_pos = [x - press_x, y - press_y];
        let [center_x, center_y] = array::from_fn(|i| (new_pos[i] + self.half_size[i]).round());
        let [_, _, center_z] = self.center;
        self.center = [center_x, center_y, center_z];
    }
}

struct AABB {
    min: [f32; 2],
    max: [f32; 2],
}
impl AABB {
    pub fn local_point(&self, x: f32, y: f32) -> [f32; 2] {
        let [left, top] = self.min;
        let local_x = x - left;
        let local_y = y - top;
        [local_x, local_y]
    }
    pub fn hit_test(&self, x: f32, y: f32) -> bool {
        let &Self {
            min: [min_x, min_y],
            max: [max_x, max_y],
        } = self;
        (min_x..max_x).contains(&x) && (min_y..max_y).contains(&y)
    }
}
