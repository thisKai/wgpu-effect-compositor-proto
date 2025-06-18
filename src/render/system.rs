use wgpu::util::DeviceExt;

pub struct SystemGroup {
    viewport_buffer: wgpu::Buffer,
    cursor_buffer: wgpu::Buffer,
    pub bind_group_layout: wgpu::BindGroupLayout,
    pub bind_group: wgpu::BindGroup,
}
impl SystemGroup {
    pub fn resize(&self, queue: &wgpu::Queue, width: u32, height: u32) {
        queue.write_buffer(
            &self.viewport_buffer,
            0,
            bytemuck::cast_slice(&[Viewport::new(width, height)]),
        );
    }
    pub fn cursor_move(&self, queue: &wgpu::Queue, x: f64, y: f64) {
        self.cursor(queue, Cursor::inside(x, y));
    }
    pub fn cursor_leave(&self, queue: &wgpu::Queue) {
        self.cursor(queue, Cursor::outside());
    }
    pub fn cursor(&self, queue: &wgpu::Queue, data: Cursor) {
        queue.write_buffer(&self.cursor_buffer, 0, bytemuck::cast_slice(&[data]));
    }
    pub fn new(device: &wgpu::Device, config: &wgpu::SurfaceConfiguration) -> Self {
        let viewport_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Viewport Buffer"),
            contents: bytemuck::cast_slice(&[Viewport::new(config.width, config.height)]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });
        let cursor_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Cursor Buffer"),
            contents: bytemuck::cast_slice(&[Cursor::outside()]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });
        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
            ],
            label: Some("Viewport Bind Group Layout"),
        });
        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: viewport_buffer.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: cursor_buffer.as_entire_binding(),
                },
            ],
            label: Some("Viewport Bind Group"),
        });
        Self {
            viewport_buffer,
            cursor_buffer,
            bind_group_layout,
            bind_group,
        }
    }
}

#[repr(C)]
#[derive(Default, Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Viewport {
    pub size_px: [f32; 2],
    pub size: [f32; 2],
    pub px: f32,
    _padding: u32,
}
impl Viewport {
    pub fn new(width: u32, height: u32) -> Self {
        let max_dimension = width.max(height) as f32;
        let pixel = 2.0 / max_dimension;
        let size_px = [width as _, height as _];
        let size_uv = size_px.map(|d| d / max_dimension);
        Self {
            size_px,
            size: size_uv,
            px: pixel,
            _padding: 0,
        }
    }
}

#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Cursor {
    pub position: [f32; 2],
}
impl Cursor {
    pub const fn outside() -> Self {
        Self {
            position: [f32::INFINITY; 2],
        }
    }
    pub const fn inside(x: f64, y: f64) -> Self {
        Self {
            position: [x as _, y as _],
        }
    }
}
