const main = {
    _wasms: new Objs(),
    _textDecoder: new TextDecoder(),

    run(_wasmPath, _canvasParent) {
        const imports = {};
        imports.env = {
            ...app,
            ...webgpu,
            ...time,
            ...res,
            ...main,
        };

        fetch(_wasmPath)
            .then(response => response.arrayBuffer())
            .then(arrayBuffer => WebAssembly.instantiate(arrayBuffer, imports))
            .then(results => {
                app.setCanvasParent(_canvasParent);
                const wasmId = main._wasms.insert({
                    _obj: results.instance.exports,
                    _canUpdate: false,
                });
                main._wasms.get(wasmId)._obj.init(wasmId);
                window.requestAnimationFrame(main.update);
            })
            .catch((err) => console.log(err));
    },

    update(timestamp) {
        for (let i = main._wasms.begin(); i < main._wasms.end(); i = main._wasms.next(i)) {
            if (main._wasms.get(i)._canUpdate) {
                main._wasms.get(i)._obj.update();
            }
        }
        window.requestAnimationFrame(main.update);
    },

    getSlice(_wasmId, _ptr, _len) {
        return main._wasms.get(_wasmId)._obj.memory.buffer.slice(_ptr, _ptr + _len);
    },

    getString(_wasmId, _ptr, _len) {
        return main._textDecoder.decode(main.getSlice(_wasmId, _ptr, _len));
    },

    logConsole(_wasmId, _msgPtr, _msgLen) {
        console.log(main.getString(_wasmId, _msgPtr, _msgLen));
    },
};

function run(_wasmPath, _canvasParent) {
    main.run(_wasmPath, _canvasParent);
}
