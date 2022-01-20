const _BaseWindowTitle = document.title;

const _app = {
    _canvases: new Objs(),
    _canvasParent: document.body,
    _observer: new IntersectionObserver(function(_entries) {
        _entries.forEach(_entry => {
            for (let _i = _app._canvases.begin();
                _i < _app._canvases.end();
                _i = _app._canvases.next(_i))
            {
                const _canvas = _app._canvases.get(_i);
                if (_canvas._obj === _entry.target) {
                    _main._wasms.get(_canvas._wasmId)._canUpdate = _entry.isIntersecting;
                }
            }
        });
    }),

    setWindowTitle(_wasmId, _titlePtr, _titleLen) {
        document.title = _titleLen > 0 ?
            _main.getString(_wasmId, _titlePtr, _titleLen) :
            _BaseWindowTitle;
    },

    setCanvasParent(_canvasParent) {
        _app._canvasParent = _canvasParent === null ?
            document.body :
            document.getElementById(_canvasParent);
    },

    createCanvas(_wasmId, _width, _height) {
        const _canvas = document.createElement("canvas");
        _canvas.width = _width;
        _canvas.height = _height;
        _app._canvasParent.appendChild(_canvas);
        _app._observer.observe(_canvas);
        return _app._canvases.insert({
            _obj: _canvas,
            _wasmId: _wasmId,
            _parent: _app._canvasParent
        });
    },
    
    destroyCanvas(_canvasId) {
        const _canvas = _app._canvases.get(_canvasId);
        _canvas._parent.removeChild(_canvas._obj);
        _app._canvases.remove(_canvasId);
    },
};
