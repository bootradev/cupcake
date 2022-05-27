class _Objs {
    _free = [];
    _objs = [null];

    _insert(_obj) {
        if (this._free.length > 0) {
            const _objId = this._free.pop();
            this._objs[_objId] = _obj;
            return _objId;
        } else {
            this._objs.push(_obj);
            return this._objs.length - 1;
        }
    }

    _remove(_objId) {
        if (_objId === this._objs.length - 1) {
            this._objs.pop();
        } else {
            this._objs[_objId] = null;
            this._free.push(_objId);
        }
    }

    _get(_objId) {
        return this._objs[_objId];
    }

    // useful for when an object has metadata and an underlying _obj field
    _getObj(_objId) {
        return this._get(_objId)._obj;
    }

    _set(_obj, _objId) {
        this._objs[_objId] = _obj;
    }

    _begin() {
        return 1;
    }

    _end() {
        return this._objs.length;
    }

    _next(_objId) {
        _objId++;
        while (_objId < this._objs.length && this._objs[_objId] == null) {
            _objId++;
        }
        return _objId;
    }
};

const _utils = {
    _textDecoder: new TextDecoder(),

    _getWasm() {
        return ccGetWasmModule();
    },

    _u8Array(_ptr, _len) {
        return new Uint8Array(_utils._getWasm().memory.buffer, _ptr, _len);
    },

    _u32Array(_ptr, _len) {
        return new Uint32Array(_utils._getWasm().memory.buffer, _ptr, _len / 4);
    },

    _getString(_ptr, _len) {
        return _utils._textDecoder.decode(_utils._u8Array(_ptr, _len));
    }
};
