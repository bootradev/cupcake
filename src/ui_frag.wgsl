struct _FragmentInput {
    @location(0) _color: vec4<f32>,
    @location(1) _uv: vec2<f32>,
};

@group(0) @binding(1) var _samp: sampler;
@group(0) @binding(2) var _tex: texture_2d<f32>;

@fragment fn fs_main(_input: _FragmentInput) -> @location(0) vec4<f32> {
    return textureSample(_tex, _samp, _input._uv) * _input._color;
}