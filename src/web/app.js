const app = {
    canvas: undefined,

    logConsole(msgPtr, msgLen) {
        console.log(utils.getString(msgPtr, msgLen));
    },
    
    setWindowTitle(titlePtr, titleLen) {
        document.title = utils.getString(titlePtr, titleLen);
    },
    
    createCanvas(width, height) {
        app.canvas = document.createElement("canvas");
        app.canvas.width = width;
        app.canvas.height = height;
        document.body.appendChild(app.canvas);
    },
};
