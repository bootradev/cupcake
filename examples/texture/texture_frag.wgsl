@group(0) @binding(1) var _samp: sampler;
@group(0) @binding(2) var _tex: texture_2d<f32>;

@stage(fragment)
fn fs_main(@location(0) _uv : vec2<f32>) -> @location(0) vec4<f32> {
    return textureSample(_tex, _samp, _uv);
}
