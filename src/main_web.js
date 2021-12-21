const textDecoder = new TextDecoder();

const main = {
    _wasm: undefined,

    run(_wasmPath) {
        const imports = {};
        imports.env = {
            ...app,
            ...webgpu,
        };

        fetch(_wasmPath)
            .then(response => response.arrayBuffer())
            .then(arrayBuffer => WebAssembly.instantiate(arrayBuffer, imports))
            .then(results => {
                main._wasm = results.instance.exports;
                main._wasm.init();
                window.requestAnimationFrame(main.update);
            })
            .catch((err) => console.log(err));
    },

    update(timestamp) {
        main._wasm.update();
        window.requestAnimationFrame(main.update);
    },

    getSlice(_ptr, _len) {
        return main._wasm.memory.buffer.slice(_ptr, _ptr + _len);
    },

    getString(_ptr, _len) {
        return textDecoder.decode(main.getSlice(_ptr, _len));
    },
};

function run(_wasmPath) {
    main.run(_wasmPath);
}
