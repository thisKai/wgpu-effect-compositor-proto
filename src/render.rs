use wesl::include_wesl;

pub struct Renderer {
    wallpaper_pipeline: wgpu::RenderPipeline,
}
impl Renderer {
    pub fn draw(&self, render_pass: &mut wgpu::RenderPass) {
        render_pass.set_pipeline(&self.wallpaper_pipeline);
        render_pass.draw(0..6, 0..1);
    }
    pub fn resize(&mut self, queue: &wgpu::Queue, width: u32, height: u32) {}
    pub fn new(device: &wgpu::Device, config: &wgpu::SurfaceConfiguration) -> Self {
        let wallpaper_shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("wallpaper shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("wallpaper").into()),
        });
        let wallpaper_render_pipeline_layout =
            device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("wallpaper pipeline layout"),
                bind_group_layouts: &[],
                push_constant_ranges: &[],
            });

        let wallpaper_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("wallpaper render pipeline"),
            layout: Some(&wallpaper_render_pipeline_layout),
            vertex: wgpu::VertexState {
                module: &wallpaper_shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &wallpaper_shader,
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

        Self { wallpaper_pipeline }
    }
}
