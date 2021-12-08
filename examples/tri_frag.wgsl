type float4 = vec4<f32>;

struct VertexOutput {
    [[builtin(position)]] position: float4;
    [[location(0)]] color: float4;
};

[[stage(fragment)]]
fn fragment_main(in: VertexOutput) -> [[location(0)]] float4 {
    return float4(in.color);
}
