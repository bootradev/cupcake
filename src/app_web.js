const baseWindowTitle = document.title;

const app = {
    canvases: [],

    logConsole(msgPtr, msgLen) {
        console.log(utils.getString(msgPtr, msgLen));
    },

    setWindowTitle(titlePtr, titleLen) {
        if (titleLen > 0) {
            document.title = utils.getString(titlePtr, titleLen);
        } else {
            document.title = baseWindowTitle;
        }
    },

    createCanvas(width, height) {
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        document.body.appendChild(canvas);
        app.canvases.push(canvas);
        return app.canvases.length - 1;
    },
    
    destroyCanvas(canvasId) {
        document.body.removeChild(app.canvases[canvasId]);
        utils.destroy(canvasId, app.canvases);
    },
};
