const RequestAdapterFailed = 0;
const RequestDeviceFailed = 1;
const CreateShaderFailed = 2;
const InvalidId = -1;

const webgpu = {
    contexts: [],
    adapters: [],
    devices: [],
    shaders: [],
    pipelineLayouts: [],
    renderPipelines: [],
    textures: [],
    commandEncoders: [],
    commandBuffers: [],

    getContext(canvasId) {
        webgpu.textures.push({});
        webgpu.contexts.push({
            obj: app.canvases[canvasId].getContext("webgpu"),
            texId: webgpu.textures.length - 1,
        });
        return webgpu.contexts.length - 1;
    },

    getContextCurrentTexture(contextId) {
        const context = webgpu.contexts[contextId];
        webgpu.textures[context.texId].obj = context.obj.getCurrentTexture();
        webgpu.textures[context.texId].views = [];
        return context.texId;
    },

    configure(deviceId, contextId, formatPtr, formatLen, usage, width, height) {
        webgpu.contexts[contextId].obj.configure({
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
        webgpu.destroy(shaderId, webgpu.shaders);
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

    createCommandEncoder(deviceId) {
        webgpu.commandEncoders.push(webgpu.devices[deviceId].createCommandEncoder());
        return webgpu.commandEncoders.length - 1;
    },

    finishCommandEncoder(commandEncoderId) {
        webgpu.commandBuffers.push(webgpu.commandEncoders[commandEncoderId].finish());
        webgpu.destroy(commandEncoderId, webgpu.commandEncoders);
        return webgpu.commandBuffers.length - 1;
    },

    queueSubmit(deviceId, commandBuffersPtr, commandBuffersLen) {
        const commandBufferIds = new Int32Array(
            utils.getSlice(commandBuffersPtr, commandBuffersLen)
        );

        let commandBuffers = [];
        for (let i = 0; i < commandBufferIds.length; ++i) {
            commandBuffers.push(webgpu.commandBuffers[commandBufferIds[i]]);
        }

        webgpu.devices[deviceId].queue.submit(commandBuffers);

        commandBufferIds.sort();
        for (let i = commandBufferIds.length - 1; i >= 0; --i) {
            webgpu.destroy(commandBufferIds[i], webgpu.commandBuffers);
        }
    },

    createTextureView(textureId) {
        const texture = webgpu.textures[textureId];
        texture.views.push(texture.obj.createView());
        return texture.views.length - 1;
    },

    destroy(id, array) {
        if (id == array.length - 1) {
            array.pop();
        }
    }
};
