[[group(0), binding(1)]] var samp: sampler;
[[group(0), binding(2)]] var tex: texture_2d<f32>;

[[stage(fragment)]]
fn fs_main([[location(0)]] uv : vec2<f32>) -> [[location(0)]] vec4<f32> {
    return textureSample(tex, samp, uv);
}
