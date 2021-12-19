const textDecoder = new TextDecoder();
const utils = {
    getSlice(_ptr, _len) {
        return main._wasm.memory.buffer.slice(_ptr, _ptr + _len);
    },

    getString(_ptr, _len) {
        return textDecoder.decode(utils.getSlice(_ptr, _len));
    },

    destroy(_id, _array) {
        if (_id == _array.length - 1) {
            _array.pop();
        }
    },
};
