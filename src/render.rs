use wallpaper::Wallpaper;

mod wallpaper;

pub struct Renderer {
    wallpaper: Wallpaper,
}
impl Renderer {
    pub fn draw(&self, render_pass: &mut wgpu::RenderPass) {
        self.wallpaper.draw(render_pass);
    }
    pub fn resize(&mut self, queue: &wgpu::Queue, width: u32, height: u32) {}
    pub fn new(
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        config: &wgpu::SurfaceConfiguration,
    ) -> Self {
        let wallpaper = Wallpaper::new(device, queue, config);

        Self { wallpaper }
    }
}
