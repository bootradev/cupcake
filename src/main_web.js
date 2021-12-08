const main = {
    wasm: undefined,

    run(wasmPath) {
        const imports = {
            app,
            webgpu,
        };

        fetch(wasmPath)
            .then(response => response.arrayBuffer())
            .then(arrayBuffer => WebAssembly.instantiate(arrayBuffer, imports))
            .then(results => {
                main.wasm = results.instance.exports;
                main.wasm.init();
                window.requestAnimationFrame(main.update);
            })
            .catch((err) => console.log(err));
    },

    update(timestamp) {
        main.wasm.update();
        window.requestAnimationFrame(main.update);
    },
};
