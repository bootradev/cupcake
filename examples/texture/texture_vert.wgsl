struct _VertexOutput {
    @builtin(position) _pos : vec4<f32>;
    @location(0) _uv: vec2<f32>;
};

@stage(vertex)
fn vs_main(@location(0) _pos : vec2<f32>, @location(1) _uv : vec2<f32>) -> _VertexOutput {
    var _output : _VertexOutput;
    _output._pos = vec4<f32>(_pos.x, _pos.y, 0.0, 1.0);
    _output._uv = _uv;
    return _output;
}
