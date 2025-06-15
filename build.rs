use wesl::{CompileOptions, ManglerKind, StandardResolver, Wesl};

fn main() {
    let wesl = {
        let resolver = StandardResolver::new("src/shaders");

        let mut wesl = Wesl::new_barebones().set_custom_resolver(resolver);
        wesl.set_mangler(ManglerKind::default())
            .set_options(CompileOptions {
                imports: true,
                condcomp: true,
                lower: true,
                validate: true,
                lazy: true,
                ..Default::default()
            });
        wesl
    };
    wesl.build_artifact("wallpaper.wesl", "wallpaper");
    wesl.build_artifact("glass.wesl", "glass");
}
