use glass::{Glass, layer::GlassLayer};
use raymarching::Raymarching;
use system::SystemGroup;
use wallpaper::Wallpaper;

mod glass;
mod pointer;
mod raymarching;
mod shape;
mod system;
mod wallpaper;

pub struct Renderer {
    system: SystemGroup,
    wallpaper: Wallpaper,
    // glass: Glass,
    // raymarching: Raymarching,
    glass_layer: GlassLayer,
}
impl Renderer {
    pub fn draw(&self, render_pass: &mut wgpu::RenderPass) {
        self.wallpaper.draw(render_pass, &self.system);
        // self.glass.draw(render_pass, &self.system, &self.wallpaper);
        // self.raymarching
        //     .draw(render_pass, &self.system, &self.wallpaper);
        self.glass_layer
            .draw(render_pass, &self.system, &self.wallpaper);
    }
    pub fn resize(&mut self, device: &wgpu::Device, queue: &wgpu::Queue, width: u32, height: u32) {
        self.system.resize(queue, width, height);
        self.glass_layer.resize(
            device,
            queue,
            &self.system,
            &self.wallpaper,
            [width, height],
        );
    }
    pub fn cursor_move(&mut self, device: &wgpu::Device, queue: &wgpu::Queue, x: f64, y: f64) {
        self.system.cursor_move(queue, x, y);
        self.glass_layer
            .cursor_move(device, queue, &self.system, &self.wallpaper, x, y);
    }
    pub fn cursor_leave(&self, queue: &wgpu::Queue) {
        self.system.cursor_leave(queue);
    }
    pub fn mouse_press(&mut self, queue: &wgpu::Queue) {
        self.glass_layer.mouse_press(queue);
    }
    pub fn mouse_release(&mut self, queue: &wgpu::Queue) {
        self.glass_layer.mouse_release(queue);
    }
    pub fn new(
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        config: &wgpu::SurfaceConfiguration,
    ) -> Self {
        let system = SystemGroup::new(device, config);
        let wallpaper = Wallpaper::new(device, queue, config, &system);
        // let glass = Glass::new(device, config, &system, &wallpaper);
        // let raymarching = Raymarching::new(device, config, &system, &wallpaper);
        let mut glass_layer = GlassLayer::new(device, config, &system, &wallpaper);

        glass_layer.insert_circle([128.0; 2], 64.0, 0x3399FFFF.into());
        glass_layer.insert_circle([256.0, 128.0], 64.0, 0xFF4444FF.into());
        glass_layer.init_gpu(device, queue, &system, &wallpaper);

        Self {
            system,
            wallpaper,
            // glass,
            // raymarching,
            glass_layer,
        }
    }
}
