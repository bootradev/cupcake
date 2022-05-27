const _BaseWindowTitle = document.title;

const _wnd = {
    _canvases: new _Objs(),
    _canvasParent: document.body,
    _observer: new IntersectionObserver(function(_entries) {
        _entries.forEach(_entry => {
            for (let i = _wnd._canvases._begin();
                i < _wnd._canvases._end();
                i = _wnd._canvases._next(i))
            {
                const _canvas = _wnd._canvases._get(i);
                if (_canvas._obj === _entry.target) {
                    _canvas._isVisible = _entry.isIntersecting;
                }
            }
        });
    }),

    setWindowTitle(_titlePtr, _titleLen) {
        document.title = _titleLen > 0 ?
            _utils._getString(_titlePtr, _titleLen) :
            _BaseWindowTitle;
    },

    createCanvas(_width, _height) {
        const _canvas = document.createElement("canvas");
        _canvas.width = _width;
        _canvas.height = _height;
        _wnd._canvasParent.appendChild(_canvas);
        _wnd._observer.observe(_canvas);
        const _canvasId = _wnd._canvases._insert({
            _obj: _canvas,
            _parent: _wnd._canvasParent,
            _isVisible: false,
        });
        _canvas.id = _canvasId;
        return _canvasId;
    },
    
    destroyCanvas(_canvasId) {
        const _canvas = _wnd._canvases._get(_canvasId);
        _canvas._parent.removeChild(_canvas._obj);
        _wnd._canvases._remove(_canvasId);
    },

    _setCanvasParent(_canvasParentId) {
        _wnd._canvasParent = _canvasParentId === null ?
            document.body :
            document.getElementById(_canvasParentId);
    },
};

function ccSetCanvasParent(_canvasParent) {
    _wnd._setCanvasParent(_canvasParent);
}
