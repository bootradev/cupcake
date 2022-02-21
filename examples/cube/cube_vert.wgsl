struct _Uniforms {
    _mvp : mat4x4<f32>;
};

@group(0) @binding(0) var<uniform> _uniforms : _Uniforms;

struct _VertexOutput {
    @builtin(position) _pos : vec4<f32>;
    @location(0) _color: vec4<f32>;
};

@stage(vertex)
fn vs_main(@location(0) _pos : vec4<f32>, @location(1) _color : vec4<f32>) -> _VertexOutput {
    var _output : _VertexOutput;
    _output._pos = _uniforms._mvp * _pos;
    _output._color = _color;
    return _output;
}
