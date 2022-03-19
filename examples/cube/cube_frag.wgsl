@stage(fragment)
fn fs_main(@location(1) _color: vec4<f32>) -> @location(0) vec4<f32> {
    return _color;
}
