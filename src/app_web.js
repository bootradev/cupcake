const baseWindowTitle = document.title;

const app = {
    _canvases: [null],

    logConsole(_msgPtr, _msgLen) {
        console.log(utils.getString(_msgPtr, _msgLen));
    },

    setWindowTitle(_titlePtr, _titleLen) {
        if (_titleLen > 0) {
            document.title = utils.getString(_titlePtr, _titleLen);
        } else {
            document.title = baseWindowTitle;
        }
    },

    createCanvas(_width, _height) {
        const canvas = document.createElement("canvas");
        canvas.width = _width;
        canvas.height = _height;
        document.body.appendChild(canvas);
        app._canvases.push(canvas);
        return app._canvases.length - 1;
    },
    
    destroyCanvas(_canvasId) {
        document.body.removeChild(app._canvases[_canvasId]);
        utils.destroy(_canvasId, app._canvases);
    },

    now() {
        return performance.now();
    },
};
