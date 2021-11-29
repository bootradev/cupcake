const RequestAdapterFailed = 0;
const RequestDeviceFailed = 1;
const CreateShaderFailed = 2;

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

    requestAdapter(powerPreferencePtr, powerPreferenceLen, forceFallbackAdapter, cb) {
        const desc = {
            powerPreference: utils.getString(powerPreferencePtr, powerPreferenceLen),
            forceFallbackAdapter: forceFallbackAdapter,
        };
        if (desc.powerPreference === "undefined") {
            desc.powerPreference = undefined;
        }
        navigator.gpu.requestAdapter(desc)
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
        const desc = JSON.parse(utils.getString(jsonPtr, jsonLen));
        webgpu.adapters[adapterId].requestDevice(desc)
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
        desc.fragment.module = webgpu.shaders[fragShaderId];
        if (desc.depthStencil === null) {
            desc.depthStencil = undefined;
        }
        if (desc.primitive.stripIndexFormat === null) {
            desc.primitive.stripIndexFormat = undefined;
        }
        webgpu.renderPipelines.push(webgpu.devices[deviceId].createRenderPipeline(desc));
        return webgpu.renderPipelines.length - 1;
    },
};
