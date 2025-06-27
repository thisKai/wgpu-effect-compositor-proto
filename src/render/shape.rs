use column::GpuColumn;
use component::{RGBA, ShapeKind, ShapeKindIndex, vec2f};
use silhouette::SilhouetteSdf;

use super::{system::SystemGroup, wallpaper::Wallpaper};

mod column;
pub mod component;
pub mod silhouette;

pub struct Shapes {
    storage: ShapesStorage,
    bind_group_layout: wgpu::BindGroupLayout,
    bind_group: Option<wgpu::BindGroup>,
    silhouette: SilhouetteSdf,
}
impl Shapes {
    pub fn new(
        device: &wgpu::Device,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        size: [u32; 2],
    ) -> Self {
        let storage = ShapesStorage::new();
        let bind_group_layout = ShapesStorage::bind_group_layout(device);

        let silhouette = SilhouetteSdf::new(device, system, wallpaper, &bind_group_layout, size);

        Self {
            storage,
            bind_group_layout,
            bind_group: None,
            silhouette,
        }
    }
    pub fn insert_circle(&mut self, center: vec2f, radius: f32, tint_color: RGBA) {
        self.storage.insert_circle(center, radius, tint_color);
    }
    pub fn resize(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        size: [u32; 2],
    ) {
        self.silhouette.resize(
            device,
            queue,
            system,
            wallpaper,
            self.bind_group.as_ref().unwrap(),
            size,
        );
    }
    pub fn bind_group_layout(&self) -> &wgpu::BindGroupLayout {
        &self.bind_group_layout
    }
    pub fn bind_group(&self) -> &wgpu::BindGroup {
        self.bind_group.as_ref().unwrap()
    }
    pub fn silhouette_bind_group_layout(&self) -> &wgpu::BindGroupLayout {
        &self.silhouette.bind_group_layout()
    }
    pub fn silhouette_bind_group(&self) -> &wgpu::BindGroup {
        self.silhouette.bind_group()
    }
    pub fn init_gpu(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
    ) {
        self.storage.init_buffers(device);
        let bind_group = self.storage.bind_group(device, &self.bind_group_layout);

        self.silhouette
            .generate(device, queue, system, wallpaper, &bind_group);

        self.bind_group = Some(bind_group);
    }
}

struct ShapesStorage {
    index_map: GpuColumn<ShapeEntry>,
    position: GpuColumn<ShapePosition>,
    appearance: GpuColumn<ShapeAppearance>,
    circle: GpuColumn<Circle>,
}
impl ShapesStorage {
    fn new() -> Self {
        Self {
            index_map: GpuColumn::new(),
            position: GpuColumn::new(),
            appearance: GpuColumn::new(),
            circle: GpuColumn::new(),
        }
    }
    fn insert_circle(&mut self, center: vec2f, radius: f32, tint_color: RGBA) {
        let circle = Circle { radius };
        let circle_index = self.circle.insert(circle);

        let shape = ShapeEntry {
            kind: ShapeKind::Circle,
            kind_index: circle_index.into(),
        };
        self.index_map.insert(shape);
        self.position.insert(ShapePosition { center });
        self.appearance.insert(ShapeAppearance { tint_color });
    }
    fn init_buffers(&mut self, device: &wgpu::Device) {
        self.index_map.init_buffer(
            device,
            wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        );
        self.position.init_buffer(
            device,
            wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        );
        self.appearance.init_buffer(
            device,
            wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        );
        self.circle.init_buffer(
            device,
            wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
        );
    }
    fn bind_group(
        &self,
        device: &wgpu::Device,
        bind_group_layout: &wgpu::BindGroupLayout,
    ) -> wgpu::BindGroup {
        device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &bind_group_layout,
            entries: &[
                self.index_map.bind_group_entry(0),
                self.position.bind_group_entry(1),
                self.appearance.bind_group_entry(2),
                self.circle.bind_group_entry(3),
            ],
            label: Some("shapes bind group"),
        })
    }
    fn bind_group_layout(device: &wgpu::Device) -> wgpu::BindGroupLayout {
        device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
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
                wgpu::BindGroupLayoutEntry {
                    binding: 3,
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
        })
    }
}

#[derive(Copy, Clone, Debug, bytemuck::NoUninit, bytemuck::CheckedBitPattern)]
#[repr(C)]
struct ShapeEntry {
    kind: ShapeKind,
    kind_index: ShapeKindIndex,
}

#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(C)]
struct ShapePosition {
    center: vec2f,
}

#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(C)]
struct ShapeAppearance {
    tint_color: RGBA,
}

#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
#[repr(C)]
struct Circle {
    radius: f32,
}
