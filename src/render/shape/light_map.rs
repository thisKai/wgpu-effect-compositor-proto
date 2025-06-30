use wesl::include_wesl;

use crate::render::system::SystemGroup;

pub struct LightMaps {
    bindings: LightMapsGroup,
    pipeline: wgpu::RenderPipeline,
}
impl LightMaps {
    pub fn bind_group(&self) -> &wgpu::BindGroup {
        &self.bindings.read_bind_group
    }
    pub fn bind_group_layout(&self) -> &wgpu::BindGroupLayout {
        &self.bindings.read_bind_group_layout
    }

    pub fn resize(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        shapes: &wgpu::BindGroup,
        silhouette: &wgpu::BindGroup,
        size: [u32; 2],
    ) {
        self.bindings.resize(device, size);
        self.generate(device, queue, system, shapes, silhouette);
    }
    pub fn generate(
        &self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        shapes: &wgpu::BindGroup,
        silhouette: &wgpu::BindGroup,
    ) {
        let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: Some("light maps render encoder"),
        });
        {
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("light maps render pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &self.bindings.textures.normals_view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color::TRANSPARENT),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                occlusion_query_set: None,
                timestamp_writes: None,
            });

            render_pass.set_pipeline(&self.pipeline);
            render_pass.set_bind_group(0, &system.bind_group, &[]);
            render_pass.set_bind_group(1, shapes, &[]);
            render_pass.set_bind_group(2, silhouette, &[]);
            render_pass.draw(0..6, 0..1);
        }
        queue.submit(std::iter::once(encoder.finish()));
    }
    pub fn new(
        device: &wgpu::Device,
        system: &SystemGroup,
        shapes_layout: &wgpu::BindGroupLayout,
        silhouette_layout: &wgpu::BindGroupLayout,
        size: [u32; 2],
    ) -> Self {
        let bindings = LightMapsGroup::new(device, size);

        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("light maps shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("light_maps").into()),
        });
        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("light maps pipeline layout"),
            bind_group_layouts: &[&system.bind_group_layout, shapes_layout, silhouette_layout],
            push_constant_ranges: &[],
        });
        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("light maps pipeline"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: wgpu::PipelineCompilationOptions {
                    ..Default::default()
                },
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format: wgpu::TextureFormat::Rgba8Unorm,
                    blend: None,
                    write_mask: Default::default(),
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

        Self { bindings, pipeline }
    }
}

struct LightMapsGroup {
    textures: LightMapTextures,
    read_bind_group_layout: wgpu::BindGroupLayout,
    read_bind_group: wgpu::BindGroup,
}
impl LightMapsGroup {
    fn new(device: &wgpu::Device, size: [u32; 2]) -> Self {
        let textures = LightMapTextures::new(device, size);
        let read_bind_group_layout = LightMapTextures::read_bind_group_layout(device);
        let read_bind_group = textures.read_bind_group(device, &read_bind_group_layout);

        Self {
            textures,
            read_bind_group_layout,
            read_bind_group,
        }
    }
    fn resize(&mut self, device: &wgpu::Device, size: [u32; 2]) {
        self.textures = LightMapTextures::new(device, size);
        self.read_bind_group = self
            .textures
            .read_bind_group(device, &self.read_bind_group_layout);
    }
}

struct LightMapTextures {
    normals: wgpu::Texture,
    normals_view: wgpu::TextureView,
}
impl LightMapTextures {
    fn new(device: &wgpu::Device, [width, height]: [u32; 2]) -> Self {
        let normals = device.create_texture(&wgpu::TextureDescriptor {
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8Unorm,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::RENDER_ATTACHMENT,
            label: None,
            view_formats: &[],
        });
        let normals_view = normals.create_view(&wgpu::TextureViewDescriptor::default());

        Self {
            normals,
            normals_view,
        }
    }
    fn read_bind_group(
        &self,
        device: &wgpu::Device,
        layout: &wgpu::BindGroupLayout,
    ) -> wgpu::BindGroup {
        let normals_sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Nearest,
            min_filter: wgpu::FilterMode::Nearest,
            mipmap_filter: wgpu::FilterMode::Nearest,
            ..Default::default()
        });

        device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(&self.normals_view),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(&normals_sampler),
                },
            ],
            label: Some("read light map textures bind group"),
        })
    }
    fn read_bind_group_layout(device: &wgpu::Device) -> wgpu::BindGroupLayout {
        device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        multisampled: false,
                        view_dimension: wgpu::TextureViewDimension::D2,
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::NonFiltering),
                    count: None,
                },
            ],
            label: Some("read light map textures bind group layout"),
        })
    }
}
