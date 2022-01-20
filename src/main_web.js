const _main = {
    _wasms: new Objs(),
    _textDecoder: new TextDecoder(),

    run(_wasmPath, _canvasParent) {
        const _imports = {};
        _imports.env = {
            ..._app,
            ..._webgpu,
            ..._time,
            ..._res,
            ..._main,
        };

        fetch(_wasmPath)
            .then(_response => _response.arrayBuffer())
            .then(_arrayBuffer => WebAssembly.instantiate(_arrayBuffer, _imports))
            .then(_results => {
                _app.setCanvasParent(_canvasParent);
                const _wasmId = _main._wasms.insert({
                    _obj: _results.instance.exports,
                    _canUpdate: false,
                });
                _main._wasms.get(_wasmId)._obj.init(_wasmId);
                window.requestAnimationFrame(_main.update);
            })
            .catch(_err => console.log(_err));
    },

    update(_timestamp) {
        //console.log(performance.memory.totalJSHeapSize);
        for (let _i = _main._wasms.begin();
            _i < _main._wasms.end();
            _i = _main._wasms.next(_i))
        {
            if (_main._wasms.get(_i)._canUpdate) {
                _main._wasms.get(_i)._obj.update();
            }
        }
        window.requestAnimationFrame(_main.update);
    },

    u8Array(_wasmId, _ptr, _len) {
        return new Uint8Array(_main._wasms.get(_wasmId)._obj.memory.buffer, _ptr, _len);
    },

    u32Array(_wasmId, _ptr, _len) {
        return new Uint32Array(_main._wasms.get(_wasmId)._obj.memory.buffer, _ptr, _len / 4);
    },

    getString(_wasmId, _ptr, _len) {
        return _main._textDecoder.decode(_main.u8Array(_wasmId, _ptr, _len));
    },

    logConsole(_wasmId, _msgPtr, _msgLen) {
        console.log(_main.getString(_wasmId, _msgPtr, _msgLen));
    },
};

function run(_wasmPath, _canvasParent) {
    _main.run(_wasmPath, _canvasParent);
}
