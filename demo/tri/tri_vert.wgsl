@vertex fn vs_main(@builtin(vertex_index) _in_vertex_index: u32) -> @builtin(position) vec4<f32> {
    let _x = f32(i32(_in_vertex_index) - 1);
    let _y = f32(i32(_in_vertex_index & 1u) * 2 - 1);
    return vec4<f32>(_x, _y, 0.0, 1.0);
}
