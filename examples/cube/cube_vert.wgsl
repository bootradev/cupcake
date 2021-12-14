[[block]] struct Uniforms {
    mvp : mat4x4<f32>;
};

[[binding(0), group(0)]] var<uniform> uniforms : Uniforms;

struct VertexOutput {
    [[builtin(position)]] position : vec4<f32>;
    [[location(0)]] color: vec4<f32>;
};

[[stage(vertex)]]
fn vs_main([[location(0)]] position : vec4<f32>, [[location(1)]] color : vec4<f32>) -> VertexOutput {
    var output : VertexOutput;
    output.position = uniforms.mvp * position;
    output.color = color;
    return output;
}
