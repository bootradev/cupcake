const RequestAdapterFailed = 0;
const RequestDeviceFailed = 1;
const CreateShaderFailed = 2;
const InvalidId = -1;
const WholeSize = 0xFFFFFFFF;
const BindTypeBuffer = 0;
const BindTypeSampler = 1;
const BindTypeTextureView = 2;

const webgpu = {
    _contexts: [],
    _adapters: [],
    _devices: [],
    _shaders: [],
    _bindGroupLayouts: [],
    _bindGroups: [],
    _pipelineLayouts: [],
    _renderPipelines: [],
    _buffers: [],
    _textures: [],
    _samplers: [],
    _commandEncoders: [],
    _commandBuffers: [],
    _renderPasses: [],
    _querySets: [],

    createContext(_canvasId) {
        webgpu._textures.push({});
        webgpu._contexts.push({
            _obj: app._canvases[_canvasId].getContext("webgpu"),
            _texId: webgpu._textures.length - 1,
        });
        return webgpu._contexts.length - 1;
    },

    destroyContext(_contextId) {
        utils.destroy(webgpu._contexts[_contextId]._texId, webgpu._textures);
        utils.destroy(_contextId, webgpu._contexts);
    },

    getContextCurrentTexture(_contextId) {
        const context = webgpu._contexts[_contextId];
        webgpu._textures[context._texId] = {
            _obj: context._obj.getCurrentTexture(),
            _views: [],
        };
        return context._texId;
    },

    configure(_deviceId, _contextId, _formatPtr, _formatLen, _usage, _width, _height) {
        const desc = {};
        desc.device = webgpu._devices[_deviceId];
        desc.format = utils.getString(_formatPtr, _formatLen);
        desc.usage = _usage;
        desc.size = [_width, _height];
        webgpu._contexts[_contextId]._obj.configure(desc);
    },

    requestAdapter(_jsonPtr, _jsonLen, _cb) {
        navigator.gpu.requestAdapter(JSON.parse(utils.getString(_jsonPtr, _jsonLen)))
            .then(adapter => {
                webgpu._adapters.push(adapter);
                main._wasm.requestAdapterComplete(webgpu._adapters.length - 1, _cb);
            })
            .catch((err) => {
                console.log(err);
                main._wasm.runtimeError(RequestAdapterFailed);
            });
    },

    destroyAdapter(_adapterId) {
        utils.destroy(_adapterId, webgpu._adapters);
    },

    requestDevice(_adapterId, _jsonPtr, _jsonLen, _cb) {
        webgpu._adapters[_adapterId].requestDevice(JSON.parse(utils.getString(_jsonPtr, _jsonLen)))
            .then(dev => {
                webgpu._devices.push(dev);
                main._wasm.requestDeviceComplete(webgpu._devices.length - 1, _cb);
            })
            .catch((err) => {
                console.log(err);
                main._wasm.runtimeError(RequestDeviceFailed);
            });
    },

    destroyDevice(_deviceId) {
        // this should be in the api?
        //webgpu._devices[_deviceId].destroy();
        utils.destroy(_deviceId, webgpu._devices);
    },

    createShader(_deviceId, _codePtr, _codeLen) {
        const desc = {};
        desc.code = utils.getString(_codePtr, _codeLen);
        webgpu._shaders.push(webgpu._devices[_deviceId].createShaderModule(desc));
        return webgpu._shaders.length - 1;
    },

    destroyShader(_shaderId) {
        utils.destroy(_shaderId, webgpu._shaders);
    },

    checkShaderCompile(_shaderId) {
        const shader = webgpu._shaders[_shaderId];
        shader.compilationInfo()
            .then(info => {
                let err = false;
                for (let i = 0; i < info.messages.length; ++i) {
                    const msg = info.messages[i];
                    console.log(`${msg.lineNum}:${msg.linePos} - ${msg.message}`);
                    err |= msg.type == "error";
                }
                if (err) {
                    main._wasm.runtimeError(CreateShaderFailed);
                }
            });
    },

    createBindGroupLayout(_deviceId, _jsonPtr, _jsonLen) {
        const desc = JSON.parse(utils.getString(_jsonPtr, _jsonLen));
        webgpu._bindGroupLayouts.push(webgpu._devices[_deviceId].createBindGroupLayout(desc));
        return webgpu._bindGroupLayouts.length - 1;
    },

    destroyBindGroupLayout(_bindGroupLayoutId) {
        utils.destroy(_bindGroupLayoutId, webgpu._bindGroupLayouts);
    },

    createBindGroup(
        _deviceId,
        _bindGroupLayoutId,
        _resourceTypesPtr,
        _resourceTypesLen,
        _resourceIdsPtr,
        _resourceIdsLen,
        _bufferOffsetsPtr,
        _bufferOffsetsLen,
        _bufferSizesPtr,
        _bufferSizesLen,
        _jsonPtr,
        _jsonLen
    ) {
        const desc = JSON.parse(utils.getString(_jsonPtr, _jsonLen));
        desc.layout = webgpu._bindGroupLayouts[_bindGroupLayoutId];

        const resourceTypes = new Uint32Array(utils.getSlice(_resourceTypesPtr, _resourceTypesLen));
        const resourceIds = new Int32Array(utils.getSlice(_resourceIdsPtr, _resourceIdsLen));
        const bufferOffsets = new Uint32Array(utils.getSlice(_bufferOffsetsPtr, _bufferOffsetsLen));
        const bufferSizes = new Uint32Array(utils.getSlice(_bufferSizesPtr, _bufferSizesLen));
        let resourceIdIndex = 0;
        for (let i = 0; i < resourceTypes.length; ++i) {
            desc.entries[i].resource = {};
            const resourceId = resourceIds[resourceIdIndex];
            switch (resourceTypes[i]) {
                case BindTypeBuffer:
                    desc.entries[i].resource.buffer = webgpu._buffers[resourceId];
                    if (bufferOffsets[i] != 0) {
                        desc.entries[i].resource.offset = bufferOffsets[i];
                    }
                    if (bufferSizes[i] != WholeSize) {
                        desc.entries[i].resource.size = bufferSizes[i];
                    }
                    resourceIdIndex++;
                    break;
                case BindTypeSampler:
                    desc.entries[i].resource.sampler = webgpu._samplers[resourceId];
                    resourceIdIndex++;
                    break;
                case BindTypeTextureView:
                    const viewId = resourceIds[resourceIdIndex + 1];
                    desc.entries[i].textureView = webgpu._textures[resourceId]._views[viewId];
                    resourceIdIndex += 2;
                    break;
            }
        }

        webgpu._bindGroups.push(webgpu._devices[_deviceId].createBindGroup(desc));
        return webgpu._bindGroups.length - 1;
    },

    destroyBindGroup(_bindGroupId) {
        utils.destroy(_bindGroupId, webgpu._bindGroups);
    },

    createPipelineLayout(_deviceId, _layoutIdsPtr, _layoutIdsLen) {
        const bindGroupLayoutIds = new Uint32Array(utils.getSlice(_layoutIdsPtr, _layoutIdsLen));
        const layouts = [];
        for (let i = 0; i < bindGroupLayoutIds.length; ++i) {
            layouts.push(webgpu._bindGroupLayouts[bindGroupLayoutIds[i]]);
        }
        const desc = {};
        desc.bindGroupLayouts = layouts; 
        webgpu._pipelineLayouts.push(webgpu._devices[_deviceId].createPipelineLayout(desc));
        return webgpu._pipelineLayouts.length - 1;
    },

    destroyPipelineLayout(_pipelineLayoutId) {
        utils.destroy(_pipelineLayoutId, webgpu._pipelineLayouts);
    },

    createRenderPipeline(_deviceId,
        _pipelineLayoutId,
        _vertShaderId,
        _fragShaderId,
        _jsonPtr,
        _jsonLen
    ) {
        const desc = JSON.parse(utils.getString(_jsonPtr, _jsonLen));
        desc.layout = webgpu._pipelineLayouts[_pipelineLayoutId];
        desc.vertex.module = webgpu._shaders[_vertShaderId];
        if (_fragShaderId != InvalidId) {
            desc.fragment.module = webgpu._shaders[_fragShaderId];
        }
        webgpu._renderPipelines.push(webgpu._devices[_deviceId].createRenderPipeline(desc));
        return webgpu._renderPipelines.length - 1;
    },

    destroyRenderPipeline(_renderPipelineId) {
        utils.destroy(_renderPipelineId, webgpu._renderPipelines);
    },

    createCommandEncoder(_deviceId) {
        webgpu._commandEncoders.push(webgpu._devices[_deviceId].createCommandEncoder());
        return webgpu._commandEncoders.length - 1;
    },

    finishCommandEncoder(_commandEncoderId) {
        webgpu._commandBuffers.push(webgpu._commandEncoders[_commandEncoderId].finish());
        utils.destroy(_commandEncoderId, webgpu._commandEncoders);
        return webgpu._commandBuffers.length - 1;
    },

    beginRenderPass(
        _commandEncoderId,
        _colorViewIdsPtr,
        _colorViewIdsLen,
        _colorResolveTargetsPtr,
        _colorResolveTargetsLen,
        _depthStencilViewTexId,
        _depthStencilViewViewId,
        _occlusionQuerySetId,
        _timestampQuerySetIdsPtr,
        _timestampQuerySetIdsLen,
        _jsonPtr,
        _jsonLen
    ) {
        const desc = JSON.parse(utils.getString(_jsonPtr, _jsonLen));

        const colorViewIds = new Int32Array(utils.getSlice(_colorViewIdsPtr, _colorViewIdsLen));
        for (let i = 0; i < desc.colorAttachments.length; ++i) {
            const colorView = webgpu._textures[colorViewIds[i * 2]]._views[colorViewIds[i * 2 + 1]];
            desc.colorAttachments[i].view = colorView;
        }

        if (_colorResolveTargetsLen > 0) {
            const colorResolveTargetIds = new Int32Array(
                utils.getSlice(_colorResolveTargetsPtr, _colorResolveTargetsLen)
            );
            for (let i = 0; i < desc.colorAttachments.length; ++i) {
                const resolve_tex = webgpu._textures[colorResolveTargetIds[i * 2]];
                const resolve_view = resolve_tex._views[colorResolveTargetIds[i * 2 + 1]];
                desc.colorAttachments[i].resolveTarget = resolve_view;
            }
        }

        if (_depthStencilViewTexId != InvalidId) {
            const dv = webgpu._textures[_depthStencilViewTexId]._views[_depthStencilViewViewId];
            desc.depthStencilAttachment.view = dv;
        }

        if (_occlusionQuerySetId != InvalidId) {
            desc.occlusionQuerySet = webgpu._querySets[_occlusionQuerySetId];
        }

        if (_timestampQuerySetIdsLen > 0) {
            let timestampQuerySetIds = new Int32Array(
                utils.getSlice(_timestampQuerySetIdsPtr, _timestampQuerySetIdsLen)
            );
            for (let i = 0; i < desc.timestampWrites.length; ++i) {
                desc.timestampWrites[i].querySet = webgpu._querySets[timestampQuerySetIds[i]];
            }
        }

        webgpu._renderPasses.push(webgpu._commandEncoders[_commandEncoderId].beginRenderPass(desc));
        return webgpu._renderPasses.length - 1;
    },

    setPipeline(_renderPassId, _pipelineId) {
        webgpu._renderPasses[_renderPassId].setPipeline(webgpu._renderPipelines[_pipelineId]);
    },

    setBindGroup(_renderPassId, _groupIndex, _bindGroupId, _dynamicOffsetsPtr, _dynamicOffsetsLen) {
        const bindGroup = webgpu._bindGroups[_bindGroupId];
        if (_dynamicOffsetsLen > 0) {
            const offsets = new Uint32Array(utils.getSlice(_dynamicOffsetsPtr, _dynamicOffsetsLen));
            webgpu._renderPasses[_renderPassId].setBindGroup(_groupIndex, bindGroup, offsets);
        } else {
            webgpu._renderPasses[_renderPassId].setBindGroup(_groupIndex, bindGroup);
        }
    },

    setVertexBuffer(_renderPassId, _slot, _bufferId, _offset, _size) {
        if ((_size >>> 0) === WholeSize) {
            _size = undefined;
        }

        webgpu._renderPasses[_renderPassId].setVertexBuffer(
            _slot,
            webgpu._buffers[_bufferId],
            _offset,
            _size
        );
    },

    setIndexBuffer(_renderPassId, _bufferId, _indexFormatPtr, _indexFormatLen, _offset, _size) {
        if ((_size >>> 0) === WholeSize) {
            _size = undefined;
        }

        webgpu._renderPasses[_renderPassId].setIndexBuffer(
            webgpu._buffers[_bufferId],
            utils.getString(_indexFormatPtr, _indexFormatLen),
            _offset,
            _size
        );
    },

    draw(_renderPassId, _vertexCount, _instanceCount, _firstVertex, _firstInstance) {
        webgpu._renderPasses[_renderPassId].draw(
            _vertexCount,
            _instanceCount,
            _firstVertex,
            _firstInstance
        );
    },

    drawIndexed(
        _renderPassId,
        _indexCount,
        _instanceCount,
        _firstIndex,
        _baseVertex,
        _firstInstance
    ) {
        webgpu._renderPasses[_renderPassId].drawIndexed(
            _indexCount,
            _instanceCount,
            _firstIndex,
            _baseVertex,
            _firstInstance
        );
    },

    endRenderPass(_renderPassId) {
        webgpu._renderPasses[_renderPassId].endPass();
        utils.destroy(_renderPassId, webgpu._renderPasses);
    },

    queueSubmit(_deviceId, _commandBuffersPtr, _commandBuffersLen) {
        const commandBufferIds = new Int32Array(
            utils.getSlice(_commandBuffersPtr, _commandBuffersLen)
        );

        let commandBuffers = [];
        for (let i = 0; i < commandBufferIds.length; ++i) {
            commandBuffers.push(webgpu._commandBuffers[commandBufferIds[i]]);
        }

        webgpu._devices[_deviceId].queue.submit(commandBuffers);

        commandBufferIds.sort();
        for (let i = commandBufferIds.length - 1; i >= 0; --i) {
            utils.destroy(commandBufferIds[i], webgpu._commandBuffers);
        }
    },

    queueWriteBuffer(_deviceId, _bufferId, _bufferOffset, _dataPtr, _dataLen, _dataOffset) {
        webgpu._devices[_deviceId].queue.writeBuffer(
            webgpu._buffers[_bufferId],
            _bufferOffset,
            new Uint8Array(utils.getSlice(_dataPtr, _dataLen)),
            _dataOffset,
            _dataLen
        );
    },

    createBuffer(_deviceId, _size, _usage, _dataPtr, _dataLen) {
        const mapped = _dataLen > 0;

        const desc = {};
        desc.size = _size;
        desc.usage = _usage;
        desc.mappedAtCreation = mapped;
        const buf = webgpu._devices[_deviceId].createBuffer(desc);

        if (mapped) {
            const src = new Uint8Array(utils.getSlice(_dataPtr, _dataLen));
            const dst = new Uint8Array(buf.getMappedRange());
            dst.set(src);
            buf.unmap();
        }

        webgpu._buffers.push(buf);
        return webgpu._buffers.length - 1;
    },

    destroyBuffer(_bufferId) {
        webgpu._buffers[_bufferId].destroy();
        utils.destroy(_bufferId, webgpu._buffers);
    },

    createTexture(
        _deviceId,
        _usage,
        _dimensionPtr,
        _dimensionLen,
        _width,
        _height,
        _depthOrArrayLayers,
        _formatPtr,
        _formatLen,
        _mipLevelCount,
        _sampleCount,
    ) {
        const desc = {};
        desc.usage = _usage;
        desc.dimension = utils.getString(_dimensionPtr, _dimensionLen);
        desc.size = {};
        desc.size.width = _width;
        desc.size.height = _height;
        desc.size.depthOrArrayLayers = _depthOrArrayLayers;
        desc.format = utils.getString(_formatPtr, _formatLen);
        desc.mipLevelCount = _mipLevelCount;
        desc.sampleCount = _sampleCount;
        const tex = webgpu._devices[_deviceId].createTexture(desc);
        webgpu._textures.push({_obj: tex, _views: []});
        return webgpu._textures.length - 1;
    },

    destroyTexture(_textureId) {
        // this should be in the api?
        //webgpu._textures[textureId].destroy();
        utils.destroy(_textureId, webgpu._textures);
    },

    createTextureView(_textureId) {
        const tex = webgpu._textures[_textureId];
        tex._views.push(tex._obj.createView());
        return tex._views.length - 1;
    },

    destroyTextureView(_textureId, _viewId) {
        utils.destroy(_viewId, webgpu._textures[_textureId]._views);
    },
};
