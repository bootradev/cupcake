const main = {
    wasm: undefined,

    run(wasmPath) {
        const imports = {
            app,
        };

        fetch(wasmPath)
            .then(response => response.arrayBuffer())
            .then(arrayBuffer => WebAssembly.instantiate(arrayBuffer, imports))
            .then(results => {
                main.wasm = results.instance.exports;
                main.wasm.mainInit();
            })
            .catch(() => console.log("Failed to initialize wasm!"));
    },
};
