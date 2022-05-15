const _res = {
    readFile(_wasmId, _namePtr, _nameLen, _filePtr, _fileLen) {
        fetch(_main._getString(_wasmId, _namePtr, _nameLen))
            .then(_response => _response.arrayBuffer())
            .then(_arrayBuffer => {
                _main._u8Array(_wasmId, _filePtr, _fileLen).set(new Uint8Array(_arrayBuffer));
                _main._wasms._getObj(_wasmId).readFileComplete(true);
            })
            .catch(_err => {
                console.log(_err);
                _main._wasms._getObj(_wasmId).readFileComplete(false);
            });
    }
};