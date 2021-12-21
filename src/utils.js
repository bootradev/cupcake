class Objs {
    _free = [];
    _objs = [null];

    insert(_obj) {
        if (this._free.length > 0) {
            const objId = this._free.pop();
            this._objs[id] = _obj;
            return objId;
        } else {
            this._objs.push(_obj);
            return this._objs.length - 1;
        }
    }

    remove(_objId) {
        if (_objId === this._objs.length - 1) {
            this._objs.pop();
        } else {
            this._objs[_objId] = null;
            this._free.push(_objId);
        }
    }

    get(_objId) {
        return this._objs[_objId];
    }

    set(_obj, _objId) {
        this._objs[_objId] = _obj;
    }
};
