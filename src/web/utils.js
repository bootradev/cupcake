const utils = {
    getSlice(ptr, len) {
        return main.wasm.memory.buffer.slice(ptr, ptr + len);
    },

    getString(ptr, len) {
        const textDecoder = new TextDecoder();
        return textDecoder.decode(utils.getSlice(ptr, len));
    },
};
