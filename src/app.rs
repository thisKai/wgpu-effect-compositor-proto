use std::sync::Arc;

use wgpu::CompositeAlphaMode;
use winit::{
    application::ApplicationHandler,
    dpi::{PhysicalPosition, PhysicalSize},
    event::{ElementState, MouseButton, WindowEvent},
    window::Window,
};

use crate::render::Renderer;

#[derive(Default)]
pub struct App {
    env: Option<WgpuEnv>,
}
impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &winit::event_loop::ActiveEventLoop) {
        let window = event_loop
            .create_window(
                Window::default_attributes()
                    // .with_decorations(false)
                    .with_transparent(true),
            )
            .unwrap();
        self.init_window(window);
    }

    fn window_event(
        &mut self,
        event_loop: &winit::event_loop::ActiveEventLoop,
        window_id: winit::window::WindowId,
        event: WindowEvent,
    ) {
        if window_id != self.window().id() {
            return;
        }
        match event {
            WindowEvent::RedrawRequested => {
                // This tells winit that we want another frame after this one
                self.window().request_redraw();

                // if !surface_configured {
                //     return;
                // }

                // state.update();
                match self.env_mut().render() {
                    Ok(_) => {}
                    // Reconfigure the surface if it's lost or outdated
                    Err(wgpu::SurfaceError::Lost | wgpu::SurfaceError::Outdated) => {
                        self.env_mut().recreate_surface();
                    }
                    // The system is out of memory, we should probably quit
                    Err(wgpu::SurfaceError::OutOfMemory | wgpu::SurfaceError::Other) => {
                        log::error!("OutOfMemory");
                        event_loop.exit();
                    }

                    // This happens when the a frame takes too long to present
                    Err(wgpu::SurfaceError::Timeout) => {
                        log::warn!("Surface timeout")
                    }
                }
            }
            WindowEvent::Resized(new_size) => {
                self.env_mut().resize(new_size);
            }
            WindowEvent::CursorMoved { position, .. } => {
                self.env_mut().cursor_move(position);
            }
            WindowEvent::CursorLeft { .. } => {
                self.env().cursor_leave();
            }
            WindowEvent::MouseInput {
                state,
                button: MouseButton::Left,
                ..
            } => match state {
                ElementState::Pressed => self.env_mut().mouse_press(),
                ElementState::Released => self.env_mut().mouse_release(),
            },
            WindowEvent::CloseRequested => {
                event_loop.exit();
            }
            _ => {}
        }
    }
}
impl App {
    fn init_window(&mut self, window: Window) {
        self.env = Some(pollster::block_on(WgpuEnv::new(window)));
    }
    fn window(&self) -> &Window {
        &self.env().window
    }
    fn env(&self) -> &WgpuEnv {
        self.env.as_ref().unwrap()
    }
    fn env_mut(&mut self) -> &mut WgpuEnv {
        self.env.as_mut().unwrap()
    }
}

struct WgpuEnv {
    renderer: Renderer,
    surface: wgpu::Surface<'static>,
    config: wgpu::SurfaceConfiguration,
    window: Arc<Window>,
    size: PhysicalSize<u32>,
    queue: wgpu::Queue,
    device: wgpu::Device,
    _instance: wgpu::Instance,
}
impl WgpuEnv {
    fn render(&mut self) -> Result<(), wgpu::SurfaceError> {
        // self.pipelines.tick(&self.queue);

        let output = self.surface.get_current_texture()?;
        let view = output
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default());
        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("Render Encoder"),
            });
        {
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("Render Pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color::TRANSPARENT),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                occlusion_query_set: None,
                timestamp_writes: None,
            });
            // self.pipelines.draw_demo(&mut render_pass);
            self.renderer.draw(&mut render_pass);
        }

        // submit will accept anything that implements IntoIter
        self.queue.submit(std::iter::once(encoder.finish()));
        self.window.pre_present_notify();
        output.present();

        Ok(())
    }
    fn recreate_surface(&mut self) {
        self.resize(self.size);
    }
    fn resize(&mut self, new_size: winit::dpi::PhysicalSize<u32>) {
        if new_size.width > 0 && new_size.height > 0 {
            self.size = new_size;
            self.config.width = new_size.width;
            self.config.height = new_size.height;
            self.surface.configure(&self.device, &self.config);
        }
        self.renderer
            .resize(&self.device, &self.queue, new_size.width, new_size.height);
    }
    fn cursor_move(&mut self, position: PhysicalPosition<f64>) {
        self.renderer
            .cursor_move(&self.queue, position.x, position.y);
    }
    fn cursor_leave(&self) {
        self.renderer.cursor_leave(&self.queue);
    }
    fn mouse_press(&mut self) {
        self.renderer.mouse_press(&self.queue);
    }
    fn mouse_release(&mut self) {
        self.renderer.mouse_release(&self.queue);
    }
    async fn new(window: Window) -> Self {
        let window = Arc::new(window);

        let size = window.inner_size();

        // The instance is a handle to our GPU
        // Backends::all => Vulkan + Metal + DX12 + Browser WebGPU
        let instance = wgpu::Instance::new(&wgpu::InstanceDescriptor {
            #[cfg(not(target_arch = "wasm32"))]
            backends: wgpu::Backends::PRIMARY,
            #[cfg(target_arch = "wasm32")]
            backends: wgpu::Backends::GL,
            flags: wgpu::InstanceFlags::advanced_debugging(),
            ..Default::default()
        });
        let surface = instance.create_surface(window.clone()).unwrap();

        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::default(),
                compatible_surface: Some(&surface),
                force_fallback_adapter: false,
            })
            .await
            .unwrap();
        // let adapter = instance
        //     .enumerate_adapters(wgpu::Backends::all())
        //     .filter(|adapter| {
        //         // Check if this adapter supports our surface
        //         adapter.is_surface_supported(&surface)
        //     })
        //     .next()
        //     .unwrap();

        let (device, queue) = adapter
            .request_device(&wgpu::DeviceDescriptor {
                required_features: wgpu::Features::POLYGON_MODE_LINE,
                // WebGL doesn't support all of wgpu's features, so if
                // we're building for the web, we'll have to disable some.
                required_limits: if cfg!(target_arch = "wasm32") {
                    wgpu::Limits::downlevel_webgl2_defaults()
                } else {
                    wgpu::Limits::default()
                },
                label: None,
                memory_hints: Default::default(),
                trace: wgpu::Trace::Off,
            })
            .await
            .unwrap();

        let surface_caps = surface.get_capabilities(&adapter);
        // Shader code in this tutorial assumes an sRGB surface texture. Using a different
        // one will result in all the colors coming out darker. If you want to support non
        // sRGB surfaces, you'll need to account for that when drawing to the frame.
        let surface_format = surface_caps
            .formats
            .iter()
            .find(|f| f.is_srgb())
            .copied()
            .unwrap_or(surface_caps.formats[0]);
        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: surface_caps.formats[0].remove_srgb_suffix(),
            width: size.width,
            height: size.height,
            present_mode: surface_caps.present_modes[0],
            alpha_mode: CompositeAlphaMode::PreMultiplied,
            view_formats: vec![surface_caps.formats[0].add_srgb_suffix()],
            desired_maximum_frame_latency: 2,
        };

        let renderer = Renderer::new(&device, &queue, &config);

        Self {
            renderer,
            surface,
            config,
            window,
            size,
            device,
            queue,
            _instance: instance,
        }
    }
}
