struct VertexOutput {
    [[builtin(position)]] pos : vec4<f32>;
    [[location(0)]] uv: vec2<f32>;
};

[[stage(vertex)]]
fn vs_main([[location(0)]] pos : vec2<f32>, [[location(1)]] uv : vec2<f32>) -> VertexOutput {
    var output : VertexOutput;
    output.pos = vec4<f32>(pos.x, pos.y, 0.0, 1.0);
    output.uv = uv;
    return output;
}
