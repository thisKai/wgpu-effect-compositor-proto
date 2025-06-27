use std::{
    ops::{Index, IndexMut},
    slice, vec,
};

use wgpu::util::DeviceExt;

use super::component::ShapeKindIndex;

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
    pub fn iter(&self) -> slice::Iter<T> {
        self.column.items.iter()
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
    pub fn update_buffer(&mut self, queue: &wgpu::Queue) {
        queue.write_buffer(&self.buffer.as_ref().unwrap(), 0, self.column.as_bytes());
    }
    pub fn bind_group_entry(&self, binding: u32) -> wgpu::BindGroupEntry {
        wgpu::BindGroupEntry {
            binding,
            resource: self.buffer.as_ref().unwrap().as_entire_binding(),
        }
    }
}

impl<T> Index<usize> for GpuColumn<T> {
    type Output = T;
    fn index(&self, index: usize) -> &Self::Output {
        &self.column.items[index]
    }
}
impl<T> IndexMut<usize> for GpuColumn<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        &mut self.column.items[index]
    }
}

impl<T> Index<u32> for GpuColumn<T> {
    type Output = T;
    fn index(&self, index: u32) -> &Self::Output {
        &self[index as usize]
    }
}
impl<T> IndexMut<u32> for GpuColumn<T> {
    fn index_mut(&mut self, index: u32) -> &mut Self::Output {
        &mut self[index as usize]
    }
}

impl<T> Index<ShapeKindIndex> for GpuColumn<T> {
    type Output = T;
    fn index(&self, index: ShapeKindIndex) -> &Self::Output {
        &self[u32::from(index)]
    }
}
impl<T> IndexMut<ShapeKindIndex> for GpuColumn<T> {
    fn index_mut(&mut self, index: ShapeKindIndex) -> &mut Self::Output {
        &mut self[u32::from(index)]
    }
}

impl<'a, T> IntoIterator for &'a GpuColumn<T> {
    type Item = &'a T;
    type IntoIter = slice::Iter<'a, T>;

    fn into_iter(self) -> Self::IntoIter {
        self.column.items.iter()
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
