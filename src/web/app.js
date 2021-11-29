const app = {
    canvases: [null],

    logConsole(msgPtr, msgLen) {
        console.log(utils.getString(msgPtr, msgLen));
    },

    setWindowTitle(titlePtr, titleLen) {
        document.title = utils.getString(titlePtr, titleLen);
    },

    createCanvas(width, height) {
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        document.body.appendChild(canvas);
        app.canvases.push(canvas);
        return app.canvases.length - 1;
    },
};
