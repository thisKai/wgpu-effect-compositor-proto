use wgpu::util::DeviceExt;

pub struct Column<T> {
    items: Vec<T>,
}
impl<T> Default for Column<T> {
    fn default() -> Self {
        Self::new()
    }
}
impl<T> Column<T> {
    pub const fn new() -> Self {
        Self { items: Vec::new() }
    }
    pub fn insert(&mut self, item: T) -> u32 {
        let index = self.items.len();
        assert!(index <= u32::MAX as _);

        self.items.push(item);
        return index as _;
    }
}
impl<T> Column<T>
where
    T: bytemuck::NoUninit,
{
    pub fn as_bytes(&self) -> &[u8] {
        bytemuck::cast_slice(&self.items)
    }
}

pub struct GpuColumn<T> {
    column: Column<T>,
    buffer: Option<wgpu::Buffer>,
}
impl<T> GpuColumn<T> {
    pub const fn new() -> Self {
        Self {
            column: Column::new(),
            buffer: None,
        }
    }
    pub fn insert(&mut self, item: T) -> u32 {
        self.column.insert(item)
    }
}
impl<T> GpuColumn<T>
where
    T: bytemuck::NoUninit,
{
    pub fn init_buffer(&mut self, device: &wgpu::Device, usage: wgpu::BufferUsages) {
        self.buffer = Some(
            device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some(std::any::type_name::<T>()),
                contents: self.column.as_bytes(),
                usage,
            }),
        );
    }
    pub fn bind_group_entry(&self, binding: u32) -> wgpu::BindGroupEntry {
        wgpu::BindGroupEntry {
            binding,
            resource: self.buffer.as_ref().unwrap().as_entire_binding(),
        }
    }
}

pub const fn bind_group_layout_entry(binding: u32) -> wgpu::BindGroupLayoutEntry {
    wgpu::BindGroupLayoutEntry {
        binding,
        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
        ty: wgpu::BindingType::Buffer {
            ty: wgpu::BufferBindingType::Storage { read_only: true },
            has_dynamic_offset: false,
            min_binding_size: None,
        },
        count: None,
    }
}
