const RequestAdapterFailed = 0;
const RequestDeviceFailed = 1;
const CreateShaderFailed = 2;
const InvalidId = -1;

const webgpu = {
    contexts: [null],
    adapters: [null],
    devices: [null],
    shaders: [null],
    pipelineLayouts: [null],
    renderPipelines: [null],

    getContext(canvasId) {
        webgpu.contexts.push(app.canvases[canvasId].getContext("webgpu"));
        return webgpu.contexts.length - 1;
    },

    configure(deviceId, contextId, formatPtr, formatLen, usage, width, height) {
        webgpu.contexts[contextId].configure({
            device: webgpu.devices[deviceId],
            format: utils.getString(formatPtr, formatLen),
            usage: usage,
            size: [width, height]
        });
    },

    requestAdapter(jsonPtr, jsonLen, cb) {
        navigator.gpu.requestAdapter(JSON.parse(utils.getString(jsonPtr, jsonLen)))
            .then(adapter => {
                webgpu.adapters.push(adapter);
                main.wasm.requestAdapterComplete(webgpu.adapters.length - 1, cb);
            })
            .catch((err) => {
                console.log(err);
                main.wasm.runtimeError(RequestAdapterFailed);
            });
    },

    requestDevice(adapterId, jsonPtr, jsonLen, cb) {
        webgpu.adapters[adapterId].requestDevice(JSON.parse(utils.getString(jsonPtr, jsonLen)))
            .then(device => {
                webgpu.devices.push(device);
                main.wasm.requestDeviceComplete(webgpu.devices.length - 1, cb);
            })
            .catch((err) => {
                console.log(err);
                main.wasm.runtimeError(RequestDeviceFailed);
            });
    },

    createShader(deviceId, codePtr, codeLen) {
        webgpu.shaders.push(webgpu.devices[deviceId].createShaderModule({
            code: utils.getString(codePtr, codeLen)
        }));
        return webgpu.shaders.length - 1;
    },

    destroyShader(shaderId) {
        if (shaderId == webgpu.shaders.length - 1) {
            webgpu.shaders.pop();
        }
    },

    checkShaderCompile(shaderId) {
        const shader = webgpu.shaders[shaderId];
        shader.compilationInfo()
            .then(info => {
                let err = false;
                for (let i = 0; i < info.messages.length; ++i) {
                    const msg = info.messages[i];
                    console.log(`${msg.lineNum}:${msg.linePos} - ${msg.message}`);
                    err |= msg.type == "error";
                }
                if (err) {
                    main.wasm.runtimeError(CreateShaderFailed);
                }
            });
    },

    createPipelineLayout(deviceId, bindGroupLayoutIdsPtr, bindGroupLayoutIdsLen) {
        webgpu.pipelineLayouts.push(webgpu.devices[deviceId].createPipelineLayout({
            bindGroupLayouts: []
        }));
        return webgpu.pipelineLayouts.length - 1;
    },

    createRenderPipeline(deviceId, pipelineLayoutId, vertShaderId, fragShaderId, jsonPtr, jsonLen) {
        const desc = JSON.parse(utils.getString(jsonPtr, jsonLen));
        desc.layout = webgpu.pipelineLayouts[pipelineLayoutId];
        desc.vertex.module = webgpu.shaders[vertShaderId];
        if (fragShaderId != InvalidId) {
            desc.fragment.module = webgpu.shaders[fragShaderId];
        }
        webgpu.renderPipelines.push(webgpu.devices[deviceId].createRenderPipeline(desc));
        return webgpu.renderPipelines.length - 1;
    },
};
