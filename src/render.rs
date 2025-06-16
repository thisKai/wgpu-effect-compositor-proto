use glass::Glass;
use system::SystemGroup;
use wallpaper::Wallpaper;

mod glass;
mod system;
mod wallpaper;

pub struct Renderer {
    system: SystemGroup,
    wallpaper: Wallpaper,
    glass: Glass,
}
impl Renderer {
    pub fn draw(&self, render_pass: &mut wgpu::RenderPass) {
        self.wallpaper.draw(render_pass, &self.system);
        self.glass.draw(render_pass, &self.system, &self.wallpaper);
    }
    pub fn resize(&mut self, queue: &wgpu::Queue, width: u32, height: u32) {
        self.system.resize(queue, width, height);
    }
    pub fn cursor_move(&mut self, queue: &wgpu::Queue, x: f64, y: f64) {
        self.system.cursor_move(queue, x, y);
        self.glass.cursor_move(queue, x, y);
    }
    pub fn cursor_leave(&self, queue: &wgpu::Queue) {
        self.system.cursor_leave(queue);
    }
    pub fn mouse_press(&mut self, queue: &wgpu::Queue) {
        self.glass.mouse_press(queue);
    }
    pub fn mouse_release(&mut self, queue: &wgpu::Queue) {
        self.glass.mouse_release(queue);
    }
    pub fn new(
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        config: &wgpu::SurfaceConfiguration,
    ) -> Self {
        let system = SystemGroup::new(device, config);
        let wallpaper = Wallpaper::new(device, queue, config, &system);
        let glass = Glass::new(device, config, &system, &wallpaper);

        Self {
            system,
            wallpaper,
            glass,
        }
    }
}
