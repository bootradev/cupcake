const baseWindowTitle = document.title;

const app = {
    _canvases: new Objs(),
    _canvasParent: document.body,
    _observer: new IntersectionObserver(function(e) {
        e.forEach(entry => {
            for (let i = app._canvases.begin();
                i < app._canvases.end();
                i = app._canvases.next(i))
            {
                const canvas = app._canvases.get(i);
                if (canvas._obj === entry.target) {
                    main._wasms.get(canvas._wasmId)._canUpdate = entry.isIntersecting;
                }
            }
        });
    }),

    logConsole(_wasmId, _msgPtr, _msgLen) {
        console.log(main.getString(_wasmId, _msgPtr, _msgLen));
    },

    setWindowTitle(_wasmId, _titlePtr, _titleLen) {
        document.title = _titleLen > 0 ?
            main.getString(_wasmId, _titlePtr, _titleLen) :
            baseWindowTitle;
    },

    setCanvasParent(_canvasParent) {
        app._canvasParent = _canvasParent === null ?
            document.body :
            document.getElementById(_canvasParent);
    },

    createCanvas(_wasmId, _width, _height) {
        const canvas = document.createElement("canvas");
        canvas.width = _width;
        canvas.height = _height;
        app._canvasParent.appendChild(canvas);
        app._observer.observe(canvas);
        return app._canvases.insert({ _obj: canvas, _wasmId: _wasmId, _parent: app._canvasParent});
    },
    
    destroyCanvas(_canvasId) {
        const canvas = app._canvases.get(_canvasId);
        canvas._parent.removeChild(canvas._obj);
        app._canvases.remove(_canvasId);
    },

    now() {
        return performance.now();
    },
};
