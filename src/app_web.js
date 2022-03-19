const _BaseWindowTitle = document.title;

const _app = {
    _canvases: new _Objs(),
    _canvasParent: document.body,
    _observer: new IntersectionObserver(function(_entries) {
        _entries.forEach(_entry => {
            for (let i = _app._canvases._begin();
                i < _app._canvases._end();
                i = _app._canvases._next(i))
            {
                const _canvas = _app._canvases._get(i);
                if (_canvas._obj === _entry.target) {
                    _main._wasms._get(_canvas._wasmId)._canUpdate = _entry.isIntersecting;
                }
            }
        });
    }),

    setWindowTitle(_wasmId, _titlePtr, _titleLen) {
        document.title = _titleLen > 0 ?
            _main._getString(_wasmId, _titlePtr, _titleLen) :
            _BaseWindowTitle;
    },

    createCanvas(_wasmId, _width, _height) {
        const _canvas = document.createElement("canvas");
        _canvas.width = _width;
        _canvas.height = _height;
        _app._canvasParent.appendChild(_canvas);
        _app._observer.observe(_canvas);
        return _app._canvases._insert({
            _obj: _canvas,
            _wasmId: _wasmId,
            _parent: _app._canvasParent
        });
    },
    
    destroyCanvas(_canvasId) {
        const _canvas = _app._canvases._get(_canvasId);
        _canvas._parent.removeChild(_canvas._obj);
        _app._canvases._remove(_canvasId);
    },

    _setCanvasParent(_canvasParent) {
        _app._canvasParent = _canvasParent === null ?
            document.body :
            document.getElementById(_canvasParent);
    },

    now() {
        return performance.now();
    },
};
