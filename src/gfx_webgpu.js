const RequestAdapterFailed = 0;
const RequestDeviceFailed = 1;
const CreateShaderFailed = 2;
const InvalidId = 0;
const WholeSize = 0xFFFFFFFF;
const BindTypeBuffer = 0;
const BindTypeSampler = 1;
const BindTypeTextureView = 2;

const webgpu = {
    _contexts: new Objs(),
    _contexts: new Objs(),
    _adapters: new Objs(),
    _devices: new Objs(),
    _shaders: new Objs(),
    _bindGroupLayouts: new Objs(),
    _bindGroups: new Objs(),
    _pipelineLayouts: new Objs(),
    _renderPipelines: new Objs(),
    _buffers: new Objs(),
    _textures: new Objs(),
    _samplers: new Objs(),
    _commandEncoders: new Objs(),
    _commandBuffers: new Objs(),
    _renderPassDescs: new Objs(),
    _renderPasses: new Objs(),
    _querySets: new Objs(),

    createContext(_canvasId) {
        return webgpu._contexts.insert({
            _obj: app._canvases.get(_canvasId)._obj.getContext("webgpu"),
            _texId: webgpu._textures.insert({}),
        });
    },

    destroyContext(_contextId) {
        webgpu._textures.remove(webgpu._contexts.get(_contextId)._texId);
        webgpu._contexts.remove(_contextId);
    },

    getContextCurrentTexture(_contextId) {
        const context = webgpu._contexts.get(_contextId);
        webgpu._textures.set({
            _obj: context._obj.getCurrentTexture(),
            _views: new Objs()
        }, context._texId);
        return context._texId;
    },

    configure(_wasmId, _deviceId, _contextId, _formatPtr, _formatLen, _usage, _width, _height) {
        const desc = {};
        desc.device = webgpu._devices.get(_deviceId);
        desc.format = main.getString(_wasmId, _formatPtr, _formatLen);
        desc.usage = _usage;
        desc.size = [_width, _height];
        webgpu._contexts.get(_contextId)._obj.configure(desc);
    },

    requestAdapter(_wasmId, _jsonPtr, _jsonLen, _adapter, _userData) {
        navigator.gpu.requestAdapter(JSON.parse(main.getString(_wasmId, _jsonPtr, _jsonLen)))
            .then(adapter => {
                main._wasms.get(_wasmId)._obj.requestAdapterComplete(
                    webgpu._adapters.insert(adapter),
                    _adapter,
                    _userData
                );
            })
            .catch((err) => {
                console.log(err);
                main._wasms.get(_wasmId)._obj.gfxError(RequestAdapterFailed);
            });
    },

    destroyAdapter(_adapterId) {
        webgpu._adapters.remove(_adapterId);
    },

    requestDevice(_wasmId, _adapterId, _jsonPtr, _jsonLen, _device, _userData) {
        const desc = JSON.parse(main.getString(_wasmId, _jsonPtr, _jsonLen));
        webgpu._adapters.get(_adapterId).requestDevice(desc)
            .then(dev => {
                main._wasms.get(_wasmId)._obj.requestDeviceComplete(
                    webgpu._devices.insert(dev), _device, _userData
                );
            })
            .catch((err) => {
                console.log(err);
                main._wasms.get(_wasmId)._obj.gfxError(RequestDeviceFailed);
            });
    },

    destroyDevice(_deviceId) {
        // device destroy should be in the api, but it's not available in chrome canary yet...
        webgpu._devices.remove(_deviceId);
    },

    createShader(_wasmId, _deviceId, _codePtr, _codeLen) {
        const desc = {};
        desc.code = main.getString(_wasmId, _codePtr, _codeLen);
        return webgpu._shaders.insert(webgpu._devices.get(_deviceId).createShaderModule(desc));
    },

    destroyShader(_shaderId) {
        webgpu._shaders.remove(_shaderId);
    },

    checkShaderCompile(_wasmId, _shaderId) {
        webgpu._shaders.get(_shaderId).compilationInfo()
            .then(info => {
                let err = false;
                for (let i = 0; i < info.messages.length; ++i) {
                    const msg = info.messages[i];
                    console.log("line:", msg.lineNum, "col:", msg.linePos, msg.message);
                    err |= msg.type == "error";
                }
                if (err) {
                    main._wasms.get(_wasmId)._obj.gfxError(CreateShaderFailed);
                }
            });
    },

    createBindGroupLayout(_wasmId, _deviceId, _jsonPtr, _jsonLen) {
        const desc = JSON.parse(main.getString(_wasmId, _jsonPtr, _jsonLen));
        return webgpu._bindGroupLayouts.insert(
            webgpu._devices.get(_deviceId).createBindGroupLayout(desc)
        );
    },

    destroyBindGroupLayout(_bindGroupLayoutId) {
        webgpu._bindGroupLayouts.remove(_bindGroupLayoutId);
    },

    createBindGroup(
        _wasmId,
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
        const desc = JSON.parse(main.getString(_wasmId, _jsonPtr, _jsonLen));
        desc.layout = webgpu._bindGroupLayouts.get(_bindGroupLayoutId);

        const resourceTypes = new Uint32Array(
            main.getSlice(_wasmId, _resourceTypesPtr, _resourceTypesLen)
        );
        const resourceIds = new Uint32Array(
            main.getSlice(_wasmId, _resourceIdsPtr, _resourceIdsLen)
        );
        const bufferOffsets = new Uint32Array(
            main.getSlice(_wasmId, _bufferOffsetsPtr, _bufferOffsetsLen)
        );
        const bufferSizes = new Uint32Array(
            main.getSlice(_wasmId, _bufferSizesPtr, _bufferSizesLen)
        );
        for (let i = 0; i < resourceTypes.length; ++i) {
            desc.entries[i].resource = {};
            switch (resourceTypes[i]) {
                case BindTypeBuffer:
                    desc.entries[i].resource.buffer = webgpu._buffers.get(resourceIds[i]);
                    if (bufferOffsets[i] != 0) {
                        desc.entries[i].resource.offset = bufferOffsets[i];
                    }
                    if (bufferSizes[i] != WholeSize) {
                        desc.entries[i].resource.size = bufferSizes[i];
                    }
                    break;
                case BindTypeSampler:
                    desc.entries[i].resource.sampler = webgpu._samplers.get(resourceIds[i]);
                    break;
                case BindTypeTextureView:
                    desc.entries[i].textureView = webgpu.getTextureView(resourceIds[i]);
                    break;
            }
        }

        return webgpu._bindGroups.insert(webgpu._devices.get(_deviceId).createBindGroup(desc));
    },

    destroyBindGroup(_bindGroupId) {
        webgpu._bindGroups.remove(_bindGroupId);
    },

    createPipelineLayout(_wasmId, _deviceId, _layoutIdsPtr, _layoutIdsLen) {
        const bindGroupLayoutIds = new Uint32Array(
            main.getSlice(_wasmId, _layoutIdsPtr, _layoutIdsLen)
        );
        const _bindGroupLayouts = [];
        for (let i = 0; i < bindGroupLayoutIds.length; ++i) {
            _bindGroupLayouts.push(webgpu._bindGroupLayouts.get(bindGroupLayoutIds[i]));
        }

        const desc = {};
        desc.bindGroupLayouts = _bindGroupLayouts;
        return webgpu._pipelineLayouts.insert(
            webgpu._devices.get(_deviceId).createPipelineLayout(desc)
        );
    },

    destroyPipelineLayout(_pipelineLayoutId) {
        webgpu._pipelineLayouts.remove(_pipelineLayoutId);
    },

    createRenderPipeline(
        _wasmId,
        _deviceId,
        _pipelineLayoutId,
        _vertShaderId,
        _fragShaderId,
        _jsonPtr,
        _jsonLen
    ) {
        const desc = JSON.parse(main.getString(_wasmId, _jsonPtr, _jsonLen));
        desc.layout = webgpu._pipelineLayouts.get(_pipelineLayoutId);
        desc.vertex.module = webgpu._shaders.get(_vertShaderId);
        if (_fragShaderId != InvalidId) {
            desc.fragment.module = webgpu._shaders.get(_fragShaderId);
        }
        return webgpu._renderPipelines.insert(
            webgpu._devices.get(_deviceId).createRenderPipeline(desc)
        );
    },

    destroyRenderPipeline(_renderPipelineId) {
        webgpu._renderPipelines.remove(_renderPipelineId);
    },

    createCommandEncoder(_deviceId) {
        return webgpu._commandEncoders.insert(
            webgpu._devices.get(_deviceId).createCommandEncoder()
        );
    },

    finishCommandEncoder(_commandEncoderId) {
        const commandBufferId = webgpu._commandBuffers.insert(
            webgpu._commandEncoders.get(_commandEncoderId).finish()
        );
        webgpu._commandEncoders.remove(_commandEncoderId);
        return commandBufferId;
    },

    beginRenderPass(
        _hash,
        _wasmId,
        _commandEncoderId,
        _colorViewIdsPtr,
        _colorViewIdsLen,
        _colorResolveTargetsPtr,
        _colorResolveTargetsLen,
        _depthStencilViewId,
        _occlusionQuerySetId,
        _timestampQuerySetIdsPtr,
        _timestampQuerySetIdsLen,
        _jsonPtr,
        _jsonLen
    ) {
        let cache = webgpu._renderPassDescs.get(_hash);
        if (cache === undefined) {
            cache = {
                _desc: JSON.parse(main.getString(_wasmId, _jsonPtr, _jsonLen)),
                _colorViewIds: new Uint32Array(
                    main.getSlice(_wasmId, _colorViewIdsPtr, _colorViewIdsLen)
                ),
                _colorResolveTargetIds: new Uint32Array(
                    main.getSlice(_wasmId, _colorResolveTargetsPtr, _colorResolveTargetsLen)
                ),
                _depthStencilViewId: _depthStencilViewId,
                _occlusionQuerySetId: _occlusionQuerySetId,
                _timestampQuerySetIds: new Uint32Array(
                    main.getSlice(_wasmId, _timestampQuerySetIdsPtr, _timestampQuerySetIdsLen)
                ),
            };

            webgpu._renderPassDescs.set(cache, _hash);
        }

        for (let i = 0; i < cache._colorViewIds.length; ++i) {
            cache._desc.colorAttachments[i].view = webgpu.getTextureView(cache._colorViewIds[i]);
        }

        for (let i = 0; i < cache._colorResolveTargetIds.length; ++i) {
            cache._desc.colorAttachments[i].resolveTarget = webgpu.getTextureView(
                cache._colorResolveTargetIds[i]
            );
        }

        if (cache._depthStencilViewId != InvalidId) {
            cache._desc.depthStencilAttachment.view = webgpu.getTextureView(
                cache._depthStencilViewId
            );
        }

        if (cache._occlusionQuerySetId != InvalidId) {
            cache._desc.occlusionQuerySet = webgpu._querySets.get(cache._occlusionQuerySetId);
        }

        for (let i = 0; i < cache._timestampQuerySetIds.length; ++i) {
            cache._desc.timestampWrites[i].querySet = webgpu._querySets.get(
                cache._timestampQuerySetIds[i]
            );
        }

        return webgpu._renderPasses.insert(
            webgpu._commandEncoders.get(_commandEncoderId).beginRenderPass(cache._desc)
        );
    },

    setPipeline(_renderPassId, _pipelineId) {
        webgpu._renderPasses.get(_renderPassId).setPipeline(
            webgpu._renderPipelines.get(_pipelineId)
        );
    },

    setBindGroup(
        _wasmId,
        _renderPassId,
        _groupIndex,
        _bindGroupId,
        _dynamicOffsetsPtr,
        _dynamicOffsetsLen
    ) {
        const dynamicOffsets = [];
        if (_dynamicOffsetsLen > 0) {
            dynamicOffsets = new Uint32Array(
                main.getSlice(_wasmId, _dynamicOffsetsPtr, _dynamicOffsetsLen)
            );
        }
        webgpu._renderPasses.get(_renderPassId).setBindGroup(
            _groupIndex,
            webgpu._bindGroups.get(_bindGroupId),
            dynamicOffsets
        );
    },

    setVertexBuffer(_renderPassId, _slot, _bufferId, _offset, _size) {
        if ((_size >>> 0) === WholeSize) {
            _size = undefined;
        }

        webgpu._renderPasses.get(_renderPassId).setVertexBuffer(
            _slot,
            webgpu._buffers.get(_bufferId),
            _offset,
            _size
        );
    },

    setIndexBuffer(
        _wasmId,
        _renderPassId,
        _bufferId,
        _indexFormatId,
        _offset,
        _size
    ) {
        if ((_size >>> 0) === WholeSize) {
            _size = undefined;
        }

        webgpu._renderPasses.get(_renderPassId).setIndexBuffer(
            webgpu._buffers.get(_bufferId),
            _indexFormatId === 1 ? "uint16" : "uint32",
            _offset,
            _size
        );
    },

    draw(_renderPassId, _vertexCount, _instanceCount, _firstVertex, _firstInstance) {
        webgpu._renderPasses.get(_renderPassId).draw(
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
        webgpu._renderPasses.get(_renderPassId).drawIndexed(
            _indexCount,
            _instanceCount,
            _firstIndex,
            _baseVertex,
            _firstInstance
        );
    },

    endRenderPass(_renderPassId) {
        webgpu._renderPasses.get(_renderPassId).endPass();
        webgpu._renderPasses.remove(_renderPassId);
    },

    queueSubmit(_wasmId, _deviceId, _commandBufferId) {
        webgpu._devices.get(_deviceId).queue.submit(
            [webgpu._commandBuffers.get(_commandBufferId)]
        );
        webgpu._commandBuffers.remove(_commandBufferId);
    },

    queueWriteBuffer(_wasmId, _deviceId, _bufferId, _bufferOffset, _dataPtr, _dataLen, _dataOffset) {
        webgpu._devices.get(_deviceId).queue.writeBuffer(
            webgpu._buffers.get(_bufferId),
            _bufferOffset,
            main._wasms.get(_wasmId)._obj.memory.buffer,
            _dataPtr + _dataOffset,
            _dataLen
        );
    },

    createBuffer(_wasmId, _deviceId, _size, _usage, _dataPtr, _dataLen) {
        const mapped = _dataLen > 0;

        const desc = {};
        desc.size = _size;
        desc.usage = _usage;
        desc.mappedAtCreation = mapped;
        const buf = webgpu._devices.get(_deviceId).createBuffer(desc);

        if (mapped) {
            const src = new Uint8Array(main.getSlice(_wasmId, _dataPtr, _dataLen));
            const dst = new Uint8Array(buf.getMappedRange());
            dst.set(src);
            buf.unmap();
        }

        return webgpu._buffers.insert(buf);
    },

    destroyBuffer(_bufferId) {
        webgpu._buffers.get(_bufferId).destroy();
        webgpu._buffers.remove(_bufferId);
    },

    createTexture(
        _wasmId,
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
        desc.dimension = main.getString(_wasmId, _dimensionPtr, _dimensionLen);
        desc.size = {};
        desc.size.width = _width;
        desc.size.height = _height;
        desc.size.depthOrArrayLayers = _depthOrArrayLayers;
        desc.format = main.getString(_wasmId, _formatPtr, _formatLen);
        desc.mipLevelCount = _mipLevelCount;
        desc.sampleCount = _sampleCount;
        return webgpu._textures.insert({
            _obj: webgpu._devices.get(_deviceId).createTexture(desc),
            _views: new Objs()
        });
    },

    destroyTexture(_textureId) {
        // texture destroy should be in the api, but it's not available in chrome canary yet...
        webgpu._textures.remove(_textureId);
    },

    createTextureView(_textureId) {
        const tex = webgpu._textures.get(_textureId);
        return (_textureId << 16) | tex._views.insert(tex._obj.createView());
    },

    destroyTextureView(_textureViewId) {
        webgpu._textures.get(_textureViewId >>> 16)._views.remove(_textureViewId & 0x0000FFFF);
    },

    getTextureView(_textureViewId) {
        return webgpu._textures.get(_textureViewId >>> 16)._views.get(_textureViewId & 0x0000FFFF);
    },
};
