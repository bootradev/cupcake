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
};

function run(_wasmPath) {
    main.run(_wasmPath);
}
