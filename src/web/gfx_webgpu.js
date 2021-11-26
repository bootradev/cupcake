const RequestAdapterFailed = 0;
const RequestDeviceFailed = 1;
const CreateShaderFailed = 2;

const webgpu = {
    adapter: undefined,
    device: undefined,
    shaders: [null],
    pipelineLayouts: [null],
    renderPipelines: [null],

    requestAdapter() {
        navigator.gpu.requestAdapter()
            .then(adapter => {
                webgpu.adapter = adapter;
                main.wasm.requestAdapterComplete();
            })
            .catch((err) => {
                console.log(err);
                main.wasm.runtimeError(RequestAdapterFailed);
            });
    },

    requestDevice() {
        webgpu.adapter.requestDevice()
            .then(device => {
                webgpu.device = device;
                main.wasm.requestDeviceComplete();
            })
            .catch((err) => {
                console.log(err);
                main.wasm.runtimeError(RequestDeviceFailed);
            });
    },

    createShader(codePtr, codeLen) {
        webgpu.shaders.push(webgpu.device.createShaderModule({
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

    createPipelineLayout(bindGroupLayoutIdsPtr, bindGroupLayoutIdsLen) {
        webgpu.pipelineLayouts.push(webgpu.device.createPipelineLayout({
            bindGroupLayouts: []
        }));
        return webgpu.pipelineLayouts.length - 1;
    },

    createRenderPipeline(pipelineLayoutId, vertShaderId, fragShaderId, jsonPtr, jsonLen) {
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
        webgpu.renderPipelines.push(webgpu.device.createRenderPipeline(desc));
        return webgpu.renderPipelines.length - 1;
    },
};
