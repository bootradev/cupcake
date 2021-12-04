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
    renderPasses: [],
    querySets: [],

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

    beginRenderPass(
        commandEncoderId,
        colorViewIdsPtr,
        colorViewIdsLen,
        colorResolveTargetsPtr,
        colorResolveTargetsLen,
        depthStencilViewTexId,
        depthStencilViewViewId,
        occlusionQuerySetId,
        timestampQuerySetIdsPtr,
        timestampQuerySetIdsLen,
        jsonPtr,
        jsonLen,
    ) {
        const desc = JSON.parse(utils.getString(jsonPtr, jsonLen));

        const colorViewIds = new Int32Array(utils.getSlice(colorViewIdsPtr, colorViewIdsLen));
        for (let i = 0; i < desc.colorAttachments.length; ++i) {
            const colorView = webgpu.textures[colorViewIds[i * 2]].views[colorViewIds[i * 2 + 1]];
            desc.colorAttachments[i].view = colorView;
        }

        if (colorResolveTargetsLen > 0) {
            const colorResolveTargetIds = new Int32Aray(
                utils.getSlice(colorResolveTargetsPtr, colorResolveTargetsLen)
            );
            for (let i = 0; i < desc.colorAttachments.length; ++i) {
                const resolve_tex = webgpu.textures[colorResolveTargetIds[i * 2]];
                const resolve_view = resolve_tex.views[colorResolveTargetIds[i * 2 + 1]];
                desc.colorAttachments[i].resolveTarget = resolve_view;
            }
        }

        if (depthStencilViewTexId != InvalidId) {
            const depth_view = webgpu.textures[depthStencilViewTexId].views[depthStencilViewViewId];
            desc.depthStencilAttachment.view = depth_view;
        }

        if (occlusionQuerySetId != InvalidId) {
            desc.occlusionQuerySet = webgpu.querySets[occlusionQuerySetId];
        }

        if (timestampQuerySetIdsLen > 0) {
            let timestampQuerySetIds = new Int32Array(
                utils.getSlice(timestampQuerySetIdsPtr, timestampQuerySetIdsLen)
            );
            for (let i = 0; i < desc.timestampWrites.length; ++i) {
                desc.timestampWrites[i].querySet = webgpu.querySets[timestampQuerySetIds[i]];
            }
        }

        webgpu.renderPasses.push(webgpu.commandEncoders[commandEncoderId].beginRenderPass(desc));
        return webgpu.renderPasses.length - 1;
    },

    endRenderPass(renderPassId) {
        webgpu.renderPasses[renderPassId].endPass();
        webgpu.destroy(renderPassId, webgpu.renderPasses);
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
