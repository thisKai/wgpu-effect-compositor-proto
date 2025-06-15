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
