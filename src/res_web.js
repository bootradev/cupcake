const _res = {
    readFile(_namePtr, _nameLen, _filePtr, _fileLen) {
        fetch(_utils._getString(_namePtr, _nameLen))
            .then(_response => _response.arrayBuffer())
            .then(_arrayBuffer => {
                _utils._u8Array(_filePtr, _fileLen).set(
                    new Uint8Array(_arrayBuffer)
                );
                _utils._getWasm().readFileComplete(true);
            })
            .catch(_err => {
                console.log(_err);
                _utils._getWasm().readFileComplete(false);
            });
    }
};