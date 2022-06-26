struct _VertexInput {
    @location(0) _pos_uv: vec4<f32>,
};

struct _InstanceInput {
    @location(1) _pos_size: vec4<f32>,
    @location(2) _uv_pos_size: vec4<f32>,
    @location(3) _color: vec4<f32>,
};

struct _VertexOutput {
    @builtin(position) _pos : vec4<f32>,
    @location(0) _color: vec4<f32>,
    @location(1) _uv: vec2<f32>
};

struct _Uniforms {
    _viewport: vec2<f32>,
};

@group(0) @binding(0) var<uniform> _uniforms : _Uniforms;

@vertex
fn vs_main(_vertex: _VertexInput, _instance: _InstanceInput) -> _VertexOutput {
    let _vertex_pos = _vertex._pos_uv.xy;
    let _vertex_uv = _vertex._pos_uv.zw;
    let _instance_pos = _instance._pos_size.xy;
    let _instance_size = _instance._pos_size.zw;
    let _instance_uv_pos = _instance._uv_pos_size.xy;
    let _instance_uv_size = _instance._uv_pos_size.zw;

    let _inst_pos = _instance_pos + _vertex_pos * _instance_size; 
    let _pos = _inst_pos / _uniforms._viewport * 2.0 - 1.0;
    let _uv = _instance_uv_pos + _vertex_uv * _instance_uv_size;

    var _output: _VertexOutput;
    _output._pos = vec4<f32>(_pos, 0.0, 1.0);
    _output._color = _instance._color;
    _output._uv = _uv;
    return _output;
}