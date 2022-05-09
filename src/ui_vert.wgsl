struct _VertexInput {
    @location(0) _pos_uv: vec4<f32>,
};

struct _InstanceInput {
    @location(2) _mvp0: vec4<f32>,
    @location(3) _mvp1: vec4<f32>,
    @location(4) _mvp2: vec4<f32>,
    @location(5) _mvp3: vec4<f32>,
};

struct _VertexOutput {
    @builtin(position) _pos : vec4<f32>,
    @location(0) _color: vec4<f32>,
};

@stage(vertex)
fn vs_main(_vertex: _VertexInput, _instance: _InstanceInput) -> _VertexOutput {
    let _pos = vec4<f32>(_vertex._pos_uv.x, _vertex._pos_uv.y, 0.0, 1.0);
    let _uv = vec2<f32>(_vertex._pos_uv.z, _vertex._pos_uv.w);
    let _mvp = mat4x4<f32>(_instance._mvp0, _instance._mvp1, _instance._mvp2, _instance._mvp3);

    var _output: _VertexOutput;
    _output._pos = _pos * _mvp;
    _output._color = vec4<f32>(_uv, 0.0, 1.0);
    return _output;
}