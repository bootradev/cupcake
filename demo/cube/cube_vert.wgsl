struct _VertexInput {
    @location(0) _pos: vec4<f32>,
    @location(1) _color: vec4<f32>,
};

struct _VertexOutput {
    @builtin(position) _pos : vec4<f32>,
    @location(0) _color: vec4<f32>,
};

struct _Uniforms {
    _mvp : mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> _uniforms : _Uniforms;

@vertex fn vs_main(_in: _VertexInput) -> _VertexOutput {
    var _out : _VertexOutput;
    _out._pos = _in._pos * _uniforms._mvp;
    _out._color = _in._color;
    return _out;
}
