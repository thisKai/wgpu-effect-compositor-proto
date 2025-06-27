use wesl::include_wesl;

use crate::{
    macros::EnumShaderConstants,
    render::{
        shape::{
            Shapes,
            component::{RGBA, ShapeKind, vec2f},
        },
        system::SystemGroup,
        wallpaper::Wallpaper,
    },
};

pub struct GlassLayer {
    shapes: Shapes,
    pipeline: wgpu::RenderPipeline,
}
impl GlassLayer {
    pub fn insert_circle(&mut self, center: vec2f, radius: f32, tint_color: RGBA) {
        self.shapes.insert_circle(center, radius, tint_color);
    }
}
impl GlassLayer {
    pub fn cursor_move(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        x: f64,
        y: f64,
    ) {
        self.shapes
            .cursor_move(device, queue, system, wallpaper, x, y);
    }
    pub fn mouse_press(&mut self, queue: &wgpu::Queue) {
        self.shapes.mouse_press(queue);
    }
    pub fn mouse_release(&mut self, queue: &wgpu::Queue) {
        self.shapes.mouse_release(queue);
    }
}
impl GlassLayer {
    pub fn draw(
        &self,
        render_pass: &mut wgpu::RenderPass,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) {
        render_pass.set_pipeline(&self.pipeline);
        render_pass.set_bind_group(0, &system.bind_group, &[]);
        render_pass.set_bind_group(1, &wallpaper.texture.bind_group, &[]);
        render_pass.set_bind_group(2, self.shapes.bind_group(), &[]);
        render_pass.set_bind_group(3, self.shapes.silhouette_bind_group(), &[]);
        render_pass.draw(0..6, 0..1);
    }
    pub fn resize(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        size: [u32; 2],
    ) {
        self.shapes.resize(device, queue, system, wallpaper, size);
    }
    pub fn init_gpu(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) {
        self.shapes.init_gpu(device, queue, system, wallpaper);
    }
    pub fn new(
        device: &wgpu::Device,
        config: &wgpu::SurfaceConfiguration,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) -> Self {
        let shapes = Shapes::new(device, system, wallpaper, [config.width, config.height]);

        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("glass shapes layer shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("glass_shapes").into()),
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("glass shapes layer render pipeline layout"),
            bind_group_layouts: &[
                &system.bind_group_layout,
                &wallpaper.texture.bind_group_layout,
                shapes.bind_group_layout(),
                shapes.silhouette_bind_group_layout(),
            ],
            push_constant_ranges: &[],
        });

        let shape_kinds = ShapeKind::SHADER_CONSTANTS;

        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("glass shapes layer render pipeline"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: wgpu::PipelineCompilationOptions {
                    constants: shape_kinds,
                    ..Default::default()
                },
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

        Self { shapes, pipeline }
    }
}
