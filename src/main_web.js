const _main = {
    _wasms: new _Objs(),
    _currentWasmId: 0,

    _run(_wasmPath) {
        const _imports = {};
        _imports.env = {
            ..._main,
            ..._res,
            ..._time,
            ..._webgpu,
            ..._wnd,
        };

        fetch(_wasmPath)
            .then(_response => _response.arrayBuffer())
            .then(_arrayBuffer => WebAssembly.instantiate(_arrayBuffer, _imports))
            .then(_mod => {
                _main._currentWasmId = _main._wasms._insert(_mod.instance.exports);
                _main._wasms._get(_main._currentWasmId).initApp();
                window.requestAnimationFrame(_main._loop);
            })
            .catch(_err => console.log(_err));
    },

    _loop(_timestamp) {
        // console.log(performance.memory.totalJSHeapSize);
        for (let i = _main._wasms._begin();
            i < _main._wasms._end();
            i = _main._wasms._next(i))
        {
            _main._currentWasmId = i;
            _main._wasms._get(i).loopApp();
        }
        window.requestAnimationFrame(_main._loop);
    },

    logConsole(_msgPtr, _msgLen) {
        console.log(_utils._getString(_msgPtr, _msgLen));
    },
};

function ccGetWasmModule() {
    return _main._wasms._get(_main._currentWasmId);
}

function ccRun(_wasmPath) {
    _main._run(_wasmPath);
}
