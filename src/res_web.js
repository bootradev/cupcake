const res = {
    loadFile(_wasmId, _namePtr, _nameLen, _filePtr, _fileLen) {
        fetch(main.getString(_wasmId, _namePtr, _nameLen))
            .then(response => response.arrayBuffer())
            .then(arrayBuffer => {
                main.u8Array(_wasmId, _filePtr, _fileLen).set(new Uint8Array(arrayBuffer));
                main._wasms.get(_wasmId)._obj.loadFileComplete(false);
            })
            .catch(err => {
                console.log(err);
                main._wasms.get(_wasmId)._obj.loadFileComplete(true);
            });
    }
};
