use std::mem;

use wesl::include_wesl;
use wgpu::util::DeviceExt;

use super::{system::SystemGroup, wallpaper::Wallpaper};

pub struct Glass {
    boxes: Vec<GlassBox>,
    instances: wgpu::Buffer,
    pipeline: wgpu::RenderPipeline,
    state: GlassState,
}
impl Glass {
    pub fn draw(
        &self,
        render_pass: &mut wgpu::RenderPass,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) {
        render_pass.set_pipeline(&self.pipeline);
        render_pass.set_bind_group(0, &system.bind_group, &[]);
        render_pass.set_bind_group(1, &wallpaper.texture.bind_group, &[]);
        render_pass.set_vertex_buffer(0, self.instances.slice(..));
        render_pass.draw(0..6, 0..self.boxes.len() as _);
    }
    pub fn cursor_move(&mut self, queue: &wgpu::Queue, x: f64, y: f64) {
        let next_state = match self.state.take() {
            GlassState::Idle => {
                let hit = self.find_hovered_glass(x, y);
                hit.map(|h| GlassState::Hovered {
                    index: h.index,
                    hover_position: h.local_position,
                })
                .unwrap_or_default()
            }
            GlassState::Hovered { index, .. } => {
                let hit = self.boxes[index].hit_test(x as _, y as _);
                match hit {
                    Some(hit) => GlassState::Hovered {
                        index,
                        hover_position: hit,
                    },
                    None => {
                        let hit = self.find_hovered_glass(x, y);
                        hit.map(|h| GlassState::Hovered {
                            index: h.index,
                            hover_position: h.local_position,
                        })
                        .unwrap_or_default()
                    }
                }
            }
            GlassState::Pressed {
                index,
                press_position,
            } => GlassState::Dragging {
                index,
                press_position,
            },
            GlassState::Dragging {
                index,
                press_position,
            } => {
                let [press_x, press_y] = press_position;
                let new_box_pos = [x as f32 - press_x, y as f32 - press_y].map(|d| d.round());

                self.boxes[index].position = new_box_pos;
                queue.write_buffer(&self.instances, 0, bytemuck::cast_slice(&self.boxes));
                dbg!(new_box_pos);
                GlassState::Dragging {
                    index,
                    press_position,
                }
            }
        };
        self.state = next_state;
    }
    pub fn mouse_press(&mut self, queue: &wgpu::Queue) {
        let next_state = match self.state.take() {
            GlassState::Idle => GlassState::Idle,
            GlassState::Hovered {
                index,
                hover_position,
            } => GlassState::Pressed {
                index,
                press_position: hover_position,
            },
            GlassState::Pressed {
                index,
                press_position,
            } => todo!(),
            GlassState::Dragging {
                index,
                press_position,
            } => todo!(),
        };
        self.state = next_state;
    }
    pub fn mouse_release(&mut self, queue: &wgpu::Queue) {
        let next_state = match self.state.take() {
            GlassState::Idle => GlassState::Idle,
            GlassState::Hovered {
                index,
                hover_position,
            } => todo!(),
            GlassState::Pressed {
                index,
                press_position,
            } => GlassState::Hovered {
                index,
                hover_position: press_position,
            },
            GlassState::Dragging {
                index,
                press_position,
            } => GlassState::Hovered {
                index,
                hover_position: press_position,
            },
        };
        self.state = next_state;
    }
    pub fn find_hovered_glass(&self, x: f64, y: f64) -> Option<GlassHit> {
        self.boxes.iter().enumerate().find_map(|(i, b)| {
            Some(GlassHit {
                index: i,
                local_position: b.hit_test(x as _, y as _)?,
            })
        })
    }
    pub fn new(
        device: &wgpu::Device,
        config: &wgpu::SurfaceConfiguration,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) -> Self {
        let boxes = vec![GlassBox::new([50.0; 2], [256.0, 256.0])];
        let instance_count = boxes.len() as u32;
        let instances = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Instance Buffer"),
            contents: bytemuck::cast_slice(&boxes),
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
        });

        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("glass shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("glass").into()),
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("glass render pipeline layout"),
            bind_group_layouts: &[
                &system.bind_group_layout,
                &wallpaper.texture.bind_group_layout,
            ],
            push_constant_ranges: &[],
        });

        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("glass render pipeline"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[GlassBox::desc()],
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
            boxes,
            instances,
            pipeline,
            state: Default::default(),
        }
    }
}

struct GlassHit {
    index: usize,
    local_position: [f32; 2],
}

#[derive(Debug, Default)]
enum GlassState {
    #[default]
    Idle,
    Hovered {
        index: usize,
        hover_position: [f32; 2],
    },
    Pressed {
        index: usize,
        press_position: [f32; 2],
    },
    Dragging {
        index: usize,
        press_position: [f32; 2],
    },
}
impl GlassState {
    fn take(&mut self) -> Self {
        mem::take(self)
    }
}

#[repr(u32)]
#[derive(Debug, Default)]
pub enum GlassPointerState {
    #[default]
    Idle,
    Hovered,
    Pressed,
    Dragging,
}

#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
pub struct GlassBox {
    pub position: [f32; 2],
    pub size: [f32; 2],
    pub pointer_state: u32,
}
impl GlassBox {
    pub fn new(position: [f32; 2], size: [f32; 2]) -> Self {
        Self {
            position,
            size,
            pointer_state: GlassPointerState::default() as _,
        }
    }
    pub fn local_point(&self, x: f32, y: f32) -> [f32; 2] {
        let [left, top] = self.position;
        let local_x = x - left;
        let local_y = y - top;
        [local_x, local_y]
    }
    pub fn hit_test(&self, x: f32, y: f32) -> Option<[f32; 2]> {
        let [x, y] = self.local_point(x, y);
        self.hit_test_local(x, y).then_some([x, y])
    }
    pub fn hit_test_local(&self, x: f32, y: f32) -> bool {
        let [width, height] = self.size;
        (0.0..width).contains(&x) && (0.0..height).contains(&y)
    }
    const ATTRIBS: [wgpu::VertexAttribute; 3] = wgpu::vertex_attr_array![
        0 => Float32x2,
        1 => Float32x2,
        2 => Uint32,
    ];
    fn desc() -> wgpu::VertexBufferLayout<'static> {
        use std::mem;

        wgpu::VertexBufferLayout {
            array_stride: mem::size_of::<Self>() as wgpu::BufferAddress,
            step_mode: wgpu::VertexStepMode::Instance,
            attributes: &Self::ATTRIBS,
        }
    }
}
