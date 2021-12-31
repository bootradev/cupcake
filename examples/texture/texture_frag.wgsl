[[stage(fragment)]]
fn fs_main([[location(0)]] uv : vec2<f32>) -> [[location(0)]] vec4<f32> {
    return vec4<f32>(uv.x, uv.y, 0.0, 1.0);
}
