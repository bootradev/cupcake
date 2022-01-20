const _res = {
    loadFile(_wasmId, _namePtr, _nameLen, _filePtr, _fileLen) {
        fetch(_main.getString(_wasmId, _namePtr, _nameLen))
            .then(_response => _response.arrayBuffer())
            .then(_arrayBuffer => {
                _main.u8Array(_wasmId, _filePtr, _fileLen).set(new Uint8Array(_arrayBuffer));
                _main._wasms.get(_wasmId)._obj.loadFileComplete(true);
            })
            .catch(_err => {
                console.log(_err);
                _main._wasms.get(_wasmId)._obj.loadFileComplete(false);
            });
    }
};
