use wesl::include_wesl;

use crate::render::{system::SystemGroup, wallpaper::Wallpaper};

pub struct SilhouetteSdf {
    bindings: SilhouetteSdfGroup,
    pipeline: wgpu::RenderPipeline,
}
impl SilhouetteSdf {
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
        wallpaper: &Wallpaper,
        shapes: &wgpu::BindGroup,
        size: [u32; 2],
    ) {
        self.bindings.resize(device, size);
        self.generate(device, queue, system, wallpaper, shapes);
    }
    pub fn generate(
        &self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        shapes: &wgpu::BindGroup,
    ) {
        let [sdf_view, tint_color_view] = self.bindings.textures.views();

        let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: Some("silhouette sdf render encoder"),
        });
        {
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("silhouette sdf render pass"),
                color_attachments: &[
                    Some(wgpu::RenderPassColorAttachment {
                        view: &sdf_view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color::TRANSPARENT),
                            store: wgpu::StoreOp::Store,
                        },
                    }),
                    Some(wgpu::RenderPassColorAttachment {
                        view: &tint_color_view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color::TRANSPARENT),
                            store: wgpu::StoreOp::Store,
                        },
                    }),
                ],
                depth_stencil_attachment: None,
                occlusion_query_set: None,
                timestamp_writes: None,
            });

            render_pass.set_pipeline(&self.pipeline);
            render_pass.set_bind_group(0, &system.bind_group, &[]);
            render_pass.set_bind_group(1, &wallpaper.texture.bind_group, &[]);
            render_pass.set_bind_group(2, shapes, &[]);
            render_pass.draw(0..6, 0..1);
        }
        queue.submit(std::iter::once(encoder.finish()));
    }
    pub fn new(
        device: &wgpu::Device,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        shapes_layout: &wgpu::BindGroupLayout,
        size: [u32; 2],
    ) -> Self {
        let bindings = SilhouetteSdfGroup::new(device, size);

        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("silhouette sdf shader"),
            source: wgpu::ShaderSource::Wgsl(include_wesl!("silhouette_sdf").into()),
        });
        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("silhouette sdf pipeline layout"),
            bind_group_layouts: &[
                &system.bind_group_layout,
                &wallpaper.texture.bind_group_layout,
                shapes_layout,
            ],
            push_constant_ranges: &[],
        });
        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("silhouette sdf pipeline"),
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
                targets: &[
                    Some(wgpu::ColorTargetState {
                        format: wgpu::TextureFormat::R32Float,
                        blend: None,
                        write_mask: Default::default(),
                    }),
                    Some(wgpu::ColorTargetState {
                        format: wgpu::TextureFormat::Rgba8Unorm,
                        blend: None,
                        write_mask: Default::default(),
                    }),
                ],
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
struct SilhouetteSdfGroup {
    textures: SilhouetteSdfTextures,
    read_bind_group_layout: wgpu::BindGroupLayout,
    read_bind_group: wgpu::BindGroup,
}
impl SilhouetteSdfGroup {
    fn new(device: &wgpu::Device, size: [u32; 2]) -> Self {
        let textures = SilhouetteSdfTextures::new(device, size);
        let read_bind_group_layout = SilhouetteSdfTextures::read_bind_group_layout(device);
        let read_bind_group = textures.read_bind_group(device, &read_bind_group_layout);

        Self {
            textures,
            read_bind_group_layout,
            read_bind_group,
        }
    }
    fn resize(&mut self, device: &wgpu::Device, size: [u32; 2]) {
        self.textures = SilhouetteSdfTextures::new(device, size);
        self.read_bind_group = self
            .textures
            .read_bind_group(device, &self.read_bind_group_layout);
    }
}
struct SilhouetteSdfTextures {
    sdf: wgpu::Texture,
    tint_color: wgpu::Texture,
}
impl SilhouetteSdfTextures {
    fn new(device: &wgpu::Device, [width, height]: [u32; 2]) -> Self {
        let sdf = device.create_texture(&wgpu::TextureDescriptor {
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::R32Float,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::RENDER_ATTACHMENT,
            label: None,
            view_formats: &[],
        });
        let tint_color = device.create_texture(&wgpu::TextureDescriptor {
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

        Self { sdf, tint_color }
    }
    fn views(&self) -> [wgpu::TextureView; 2] {
        let sdf_view = self
            .sdf
            .create_view(&wgpu::TextureViewDescriptor::default());

        let tint_color_view = self
            .tint_color
            .create_view(&wgpu::TextureViewDescriptor::default());

        [sdf_view, tint_color_view]
    }
    fn read_bind_group(
        &self,
        device: &wgpu::Device,
        layout: &wgpu::BindGroupLayout,
    ) -> wgpu::BindGroup {
        let sdf_view = self
            .sdf
            .create_view(&wgpu::TextureViewDescriptor::default());
        let sdf_sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Nearest,
            min_filter: wgpu::FilterMode::Nearest,
            mipmap_filter: wgpu::FilterMode::Nearest,
            ..Default::default()
        });

        let tint_color_view = self
            .tint_color
            .create_view(&wgpu::TextureViewDescriptor::default());
        let tint_color_sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            mipmap_filter: wgpu::FilterMode::Linear,
            ..Default::default()
        });

        device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(&sdf_view),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(&sdf_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: wgpu::BindingResource::TextureView(&tint_color_view),
                },
                wgpu::BindGroupEntry {
                    binding: 3,
                    resource: wgpu::BindingResource::Sampler(&tint_color_sampler),
                },
            ],
            label: Some("read silhouette sdf textures bind group"),
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
                        sample_type: wgpu::TextureSampleType::Float { filterable: false },
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::NonFiltering),
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 2,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        multisampled: false,
                        view_dimension: wgpu::TextureViewDimension::D2,
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 3,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None,
                },
            ],
            label: Some("read silhouette sdf textures bind group layout"),
        })
    }
}
