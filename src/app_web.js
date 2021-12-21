const baseWindowTitle = document.title;

const app = {
    _canvases: new Objs(),

    logConsole(_msgPtr, _msgLen) {
        console.log(main.getString(_msgPtr, _msgLen));
    },

    setWindowTitle(_titlePtr, _titleLen) {
        if (_titleLen > 0) {
            document.title = main.getString(_titlePtr, _titleLen);
        } else {
            document.title = baseWindowTitle;
        }
    },

    createCanvas(_width, _height) {
        const canvas = document.createElement("canvas");
        canvas.width = _width;
        canvas.height = _height;
        document.body.appendChild(canvas);
        return app._canvases.insert(canvas);
    },
    
    destroyCanvas(_canvasId) {
        document.body.removeChild(app._canvases.get(_canvasId));
        app._canvases.remove(_canvasId);
    },

    now() {
        return performance.now();
    },
};
