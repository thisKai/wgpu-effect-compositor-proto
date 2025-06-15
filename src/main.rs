use app::App;
use winit::event_loop::EventLoop;

mod app;
mod render;

fn main() {
    env_logger::init();

    let event_loop = EventLoop::new().unwrap();
    let mut app = App::default();
    event_loop.run_app(&mut app).unwrap();
}
