use column::GpuColumn;
use component::{RGBA, ShapeKind, ShapeKindIndex, vec2f};
use silhouette::SilhouetteSdf;

use super::{
    pointer::{AABB, BoundingBox, PointerHit, PointerState},
    system::SystemGroup,
    wallpaper::Wallpaper,
};

mod column;
pub mod component;
pub mod silhouette;

pub struct Shapes {
    storage: ShapesStorage,
    bind_group_layout: wgpu::BindGroupLayout,
    bind_group: Option<wgpu::BindGroup>,
    silhouette: SilhouetteSdf,
    state: PointerState,
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
            state: Default::default(),
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
impl Shapes {
    pub fn cursor_move(
        &mut self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        system: &SystemGroup,
        wallpaper: &Wallpaper,
        x: f64,
        y: f64,
    ) {
        self.state = match self.state.take() {
            PointerState::Idle => {
                let hit = self.storage.find_hovered(x, y);
                hit.map(|h| PointerState::Hovered {
                    index: h.index,
                    hover_position: h.local_position,
                })
                .unwrap_or_default()
            }
            PointerState::Hovered { index, .. } => {
                let hit = self.storage.check_hovered(index as _, x, y);
                match hit {
                    Some(hit) => PointerState::Hovered {
                        index,
                        hover_position: hit,
                    },
                    None => {
                        let hit = self.storage.find_hovered(x, y);
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
                self.storage
                    .drag_move(queue, index as _, press_position, [x as _, y as _]);
                self.silhouette
                    .generate(device, queue, system, wallpaper, &self.bind_group());

                PointerState::Dragging {
                    index,
                    press_position,
                }
            }
        };
    }
    pub fn mouse_press(&mut self, queue: &wgpu::Queue) {
        self.state = match self.state.take() {
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
    }
    pub fn mouse_release(&mut self, queue: &wgpu::Queue) {
        self.state = match self.state.take() {
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
    }
}

struct ShapesStorage {
    index_map: GpuColumn<ShapeEntry>,
    position: GpuColumn<ShapePosition>,
    appearance: GpuColumn<ShapeAppearance>,
    circle: GpuColumn<Circle>,
}
impl ShapesStorage {
    fn drag_move(
        &mut self,
        queue: &wgpu::Queue,
        shape: u32,
        press_position: [f32; 2],
        cursor_position: [f32; 2],
    ) {
        let [x, y] = cursor_position;
        let [press_x, press_y] = press_position;
        let new_min_bound = [x - press_x, y - press_y].map(|d| d.round());
        let entry = self.index_map[shape];
        match entry.kind {
            ShapeKind::Circle => {
                let circle = &self.circle[entry.kind_index];
                let [center_x, center_y] = new_min_bound.map(|d| d + circle.radius);
                self.position[shape].center = [center_x, center_y];
            }
        }
        self.position.update_buffer(queue);
    }
    fn find_hovered(&self, x: f64, y: f64) -> Option<PointerHit> {
        let [x, y] = [x as f32, y as f32];
        self.index_map
            .iter()
            .enumerate()
            .map(|(i, s)| {
                (
                    i,
                    match s.kind {
                        ShapeKind::Circle => self.circle[s.kind_index]
                            .bounding_box()
                            .with_center(self.position[i].center),
                    },
                )
            })
            .find_map(|(i, b)| {
                Some(PointerHit {
                    index: i,
                    local_position: b.hit_test(x, y).then(|| b.local_point(x, y))?,
                })
            })
    }
    fn check_hovered(&self, shape: u32, x: f64, y: f64) -> Option<[f32; 2]> {
        let [x, y] = [x as f32, y as f32];
        let b = self.bounding_box(shape);
        b.hit_test(x, y).then(|| b.local_point(x, y))
    }
    fn bounding_box(&self, shape: u32) -> AABB {
        let entry = self.index_map[shape];
        match entry.kind {
            ShapeKind::Circle => self.circle[entry.kind_index]
                .bounding_box()
                .with_center(self.position[shape].center),
        }
    }
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
impl BoundingBox for Circle {
    fn bounding_box(&self) -> super::pointer::AABB {
        AABB {
            min: [-self.radius; 2],
            max: [self.radius; 2],
        }
    }
}
