use std::mem;

use wesl::include_wesl;
use wgpu::util::DeviceExt;

use super::{system::SystemGroup, wallpaper::Wallpaper};

pub struct Raymarching {
    shapes: Vec<Shape>,
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
        render_pass.draw(0..6, 0..1);
    }
    pub fn store_shapes(&mut self) {
        let mut shapes = Vec::new();
        let mut spheres = Vec::new();

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
            }
        }
    }
    pub fn new(
        device: &wgpu::Device,
        config: &wgpu::SurfaceConfiguration,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) -> Self {
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("raymarching shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("raymarching").into()),
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("raymarching render pipeline layout"),
            bind_group_layouts: &[
                &system.bind_group_layout,
                &wallpaper.texture.bind_group_layout,
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

        let shapes = vec![
            Shape::Sphere(Sphere {
                center: [-0.25, -0.25, 0.0],
                radius: 0.25,
            }),
            Shape::Sphere(Sphere {
                center: [0.25, 0.25, 0.0],
                radius: 0.25,
            }),
        ];

        Self { pipeline, shapes }
    }
}

enum Shape {
    Sphere(Sphere),
}

#[repr(u32)]
enum ShapeKind {
    None,
    Sphere,
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
