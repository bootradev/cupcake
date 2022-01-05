const RequestFileFailed = 0;

const res = {
    requestFile(_wasmId, _namePtr, _nameLen, _dataPtr, _dataLen, _userData) {
        fetch(main.getString(_wasmId, _namePtr, _nameLen))
            .then(response => response.arrayBuffer())
            .then(arrayBuffer => {
                new Uint8Array(main.getSlice(_dataPtr, _dataLen)).set(new Uint8Array(arrayBuffer));
                main._wasms.get(_wasmId).obj.requestFileComplete(
                    _dataPtr,
                    _dataLen,
                    _userData
                );
            })
            .catch(err => {
                console.log(err);
                main._wasms.get(_wasmId)._obj.resError(RequestFileFailed, _userData);
            });
    }
};
