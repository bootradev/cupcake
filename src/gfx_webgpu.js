const _InvalidId = 0;
const _WholeSize = 0xFFFFFFFF;
const _BindTypeBuffer = 0;
const _BindTypeSampler = 1;
const _BindTypeTextureView = 2;

const _webgpu = {
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
        return _webgpu._contexts.insert({
            _obj: _app._canvases.get(_canvasId)._obj.getContext("webgpu"),
            _texId: _webgpu._textures.insert({}),
        });
    },

    destroyContext(_contextId) {
        _webgpu._textures.remove(_webgpu._contexts.get(_contextId)._texId);
        _webgpu._contexts.remove(_contextId);
    },

    getContextCurrentTexture(_contextId) {
        const _context = _webgpu._contexts.get(_contextId);
        _webgpu._textures.set({
            _obj: _context._obj.getCurrentTexture(),
            _views: new Objs()
        }, _context._texId);
        return _context._texId;
    },

    configure(_wasmId, _deviceId, _contextId, _formatPtr, _formatLen, _usage, _width, _height) {
        const _desc = {};
        _desc.device = _webgpu._devices.get(_deviceId);
        _desc.format = _main.getString(_wasmId, _formatPtr, _formatLen);
        _desc.usage = _usage;
        _desc.size = [_width, _height];
        _webgpu._contexts.get(_contextId)._obj.configure(_desc);
    },

    requestAdapter(_wasmId, _jsonPtr, _jsonLen) {
        navigator.gpu.requestAdapter(JSON.parse(_main.getString(_wasmId, _jsonPtr, _jsonLen)))
            .then(_adapter => {
                _main._wasms.get(_wasmId)._obj.requestAdapterComplete(
                    _webgpu._adapters.insert(_adapter)
                );
            })
            .catch(_err => {
                console.log(_err);
                _main._wasms.get(_wasmId)._obj.requestAdapterComplete(_InvalidId);
            });
    },

    destroyAdapter(_adapterId) {
        _webgpu._adapters.remove(_adapterId);
    },

    requestDevice(_wasmId, _adapterId, _jsonPtr, _jsonLen) {
        const _desc = JSON.parse(_main.getString(_wasmId, _jsonPtr, _jsonLen));
        _webgpu._adapters.get(_adapterId).requestDevice(_desc)
            .then(_device=> {
                _main._wasms.get(_wasmId)._obj.requestDeviceComplete(
                    _webgpu._devices.insert(_device)
                );
            })
            .catch(_err => {
                console.log(_err);
                _main._wasms.get(_wasmId)._obj.requestDeviceComplete(_InvalidId);
            });
    },

    destroyDevice(_deviceId) {
        // device destroy should be in the api, but it's not available in chrome canary yet...
        _webgpu._devices.remove(_deviceId);
    },

    createShader(_wasmId, _deviceId, _codePtr, _codeLen) {
        const _desc = {};
        _desc.code = _main.getString(_wasmId, _codePtr, _codeLen);
        return _webgpu._shaders.insert(
            _webgpu._devices.get(_deviceId).createShaderModule(_desc)
        );
    },

    destroyShader(_shaderId) {
        _webgpu._shaders.remove(_shaderId);
    },

    checkShaderCompile(_wasmId, _shaderId) {
        _webgpu._shaders.get(_shaderId).compilationInfo()
            .then(_info => {
                let _err = false;
                for (let _i = 0; _i < _info.messages.length; ++_i) {
                    const _msg = _info.messages[_i];
                    console.log("line:", _msg.lineNum, "col:", _msg.linePos, _msg.message);
                    _err |= _msg.type == "error";
                }
                _main._wasms.get(_wasmId)._obj.checkShaderCompileComplete(_err);
            });
    },

    createBindGroupLayout(_wasmId, _deviceId, _jsonPtr, _jsonLen) {
        const _desc = JSON.parse(_main.getString(_wasmId, _jsonPtr, _jsonLen));
        return _webgpu._bindGroupLayouts.insert(
            _webgpu._devices.get(_deviceId).createBindGroupLayout(_desc)
        );
    },

    destroyBindGroupLayout(_bindGroupLayoutId) {
        _webgpu._bindGroupLayouts.remove(_bindGroupLayoutId);
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
        const _desc = JSON.parse(_main.getString(_wasmId, _jsonPtr, _jsonLen));
        _desc.layout = _webgpu._bindGroupLayouts.get(_bindGroupLayoutId);

        const _resourceTypes = _main.u32Array(_wasmId, _resourceTypesPtr, _resourceTypesLen);
        const _resourceIds = _main.u32Array(_wasmId, _resourceIdsPtr, _resourceIdsLen);
        const _bufferOffsets = _main.u32Array(_wasmId, _bufferOffsetsPtr, _bufferOffsetsLen);
        const _bufferSizes = _main.u32Array(_wasmId, _bufferSizesPtr, _bufferSizesLen);
        for (let _i = 0; _i < _resourceTypes.length; ++_i) {
            _desc.entries[_i].resource = {};
            switch (_resourceTypes[_i]) {
                case _BindTypeBuffer:
                    _desc.entries[_i].resource.buffer = _webgpu._buffers.get(_resourceIds[_i]);
                    if (_bufferOffsets[_i] != 0) {
                        _desc.entries[_i].resource.offset = _bufferOffsets[_i];
                    }
                    if (_bufferSizes[_i] != _WholeSize) {
                        _desc.entries[_i].resource.size = _bufferSizes[_i];
                    }
                    break;
                case _BindTypeSampler:
                    _desc.entries[_i].resource.sampler = _webgpu._samplers.get(_resourceIds[_i]);
                    break;
                case _BindTypeTextureView:
                    _desc.entries[_i].textureView = _webgpu.getTextureView(_resourceIds[_i]);
                    break;
            }
        }

        return _webgpu._bindGroups.insert(
            _webgpu._devices.get(_deviceId).createBindGroup(_desc)
        );
    },

    destroyBindGroup(_bindGroupId) {
        _webgpu._bindGroups.remove(_bindGroupId);
    },

    createPipelineLayout(_wasmId, _deviceId, _layoutIdsPtr, _layoutIdsLen) {
        const _bindGroupLayoutIds = _main.u32Array(_wasmId, _layoutIdsPtr, _layoutIdsLen);
        const _bindGroupLayouts = [];
        for (let _i = 0; _i < _bindGroupLayoutIds.length; ++_i) {
            _bindGroupLayouts.push(_webgpu._bindGroupLayouts.get(_bindGroupLayoutIds[_i]));
        }

        const _desc = {};
        _desc.bindGroupLayouts = _bindGroupLayouts;
        return _webgpu._pipelineLayouts.insert(
            _webgpu._devices.get(_deviceId).createPipelineLayout(_desc)
        );
    },

    destroyPipelineLayout(_pipelineLayoutId) {
        _webgpu._pipelineLayouts.remove(_pipelineLayoutId);
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
        const _desc = JSON.parse(_main.getString(_wasmId, _jsonPtr, _jsonLen));
        _desc.layout = _webgpu._pipelineLayouts.get(_pipelineLayoutId);
        _desc.vertex.module = _webgpu._shaders.get(_vertShaderId);
        if (_fragShaderId != _InvalidId) {
            _desc.fragment.module = _webgpu._shaders.get(_fragShaderId);
        }
        return _webgpu._renderPipelines.insert(
            _webgpu._devices.get(_deviceId).createRenderPipeline(_desc)
        );
    },

    destroyRenderPipeline(_renderPipelineId) {
        _webgpu._renderPipelines.remove(_renderPipelineId);
    },

    createCommandEncoder(_deviceId) {
        return _webgpu._commandEncoders.insert(
            _webgpu._devices.get(_deviceId).createCommandEncoder()
        );
    },

    finishCommandEncoder(_commandEncoderId) {
        const _commandBufferId = _webgpu._commandBuffers.insert(
            _webgpu._commandEncoders.get(_commandEncoderId).finish()
        );
        _webgpu._commandEncoders.remove(_commandEncoderId);
        return _commandBufferId;
    },

    beginRenderPass(
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

        const _desc = JSON.parse(_main.getString(_wasmId, _jsonPtr, _jsonLen));
        const _colorViewIds = _main.u32Array(_wasmId, _colorViewIdsPtr, _colorViewIdsLen);
        const _colorResolveTargetIds = _main.u32Array(
            _wasmId,
            _colorResolveTargetsPtr,
            _colorResolveTargetsLen
        );
        const _timestampQuerySetIds = _main.u32Array(
            _wasmId,
            _timestampQuerySetIdsPtr,
            _timestampQuerySetIdsLen
        );

        for (let _i = 0; _i < _colorViewIds.length; ++_i) {
            _desc.colorAttachments[_i].view = _webgpu.getTextureView(_colorViewIds[_i]);
        }

        for (let _i = 0; _i < _colorResolveTargetIds.length; ++_i) {
            _desc.colorAttachments[_i].resolveTarget = _webgpu.getTextureView(
                _colorResolveTargetIds[_i]
            );
        }

        if (_depthStencilViewId != _InvalidId) {
            _desc.depthStencilAttachment.view = _webgpu.getTextureView(_depthStencilViewId);
        }

        if (_occlusionQuerySetId != _InvalidId) {
            _desc.occlusionQuerySet = _webgpu._querySets.get(_occlusionQuerySetId);
        }

        for (let _i = 0; _i < _timestampQuerySetIds.length; ++_i) {
            _desc.timestampWrites[_i].querySet = _webgpu._querySets.get(
                _timestampQuerySetIds[_i]
            );
        }

        return _webgpu._renderPasses.insert(
            _webgpu._commandEncoders.get(_commandEncoderId).beginRenderPass(_desc)
        );
    },

    setPipeline(_renderPassId, _pipelineId) {
        _webgpu._renderPasses.get(_renderPassId).setPipeline(
            _webgpu._renderPipelines.get(_pipelineId)
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
        const _dynamicOffsets = [];
        if (_dynamicOffsetsLen > 0) {
            _dynamicOffsets = _main.u32Array(_wasmId, _dynamicOffsetsPtr, _dynamicOffsetsLen);
        }
        _webgpu._renderPasses.get(_renderPassId).setBindGroup(
            _groupIndex,
            _webgpu._bindGroups.get(_bindGroupId),
            _dynamicOffsets
        );
    },

    setVertexBuffer(_renderPassId, _slot, _bufferId, _offset, _size) {
        if ((_size >>> 0) === _WholeSize) {
            _size = undefined;
        }

        _webgpu._renderPasses.get(_renderPassId).setVertexBuffer(
            _slot,
            _webgpu._buffers.get(_bufferId),
            _offset,
            _size
        );
    },

    setIndexBuffer(
        _wasmId,
        _renderPassId,
        _bufferId,
        _indexFormatPtr,
        _indexFormatLen,
        _offset,
        _size
    ) {
        if ((_size >>> 0) === _WholeSize) {
            _size = undefined;
        }

        _webgpu._renderPasses.get(_renderPassId).setIndexBuffer(
            _webgpu._buffers.get(_bufferId),
            _main.getString(_wasmId, _indexFormatPtr, _indexFormatLen),
            _offset,
            _size
        );
    },

    draw(_renderPassId, _vertexCount, _instanceCount, _firstVertex, _firstInstance) {
        _webgpu._renderPasses.get(_renderPassId).draw(
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
        _webgpu._renderPasses.get(_renderPassId).drawIndexed(
            _indexCount,
            _instanceCount,
            _firstIndex,
            _baseVertex,
            _firstInstance
        );
    },

    endRenderPass(_renderPassId) {
        _webgpu._renderPasses.get(_renderPassId).endPass();
        _webgpu._renderPasses.remove(_renderPassId);
    },

    queueSubmit(_wasmId, _deviceId, _commandBufferId) {
        _webgpu._devices.get(_deviceId).queue.submit(
            [_webgpu._commandBuffers.get(_commandBufferId)]
        );
        _webgpu._commandBuffers.remove(_commandBufferId);
    },

    queueWriteBuffer(
        _wasmId,
        _deviceId,
        _bufferId,
        _bufferOffset,
        _dataPtr,
        _dataLen,
        _dataOffset
    ) {
        _webgpu._devices.get(_deviceId).queue.writeBuffer(
            _webgpu._buffers.get(_bufferId),
            _bufferOffset,
            _main._wasms.get(_wasmId)._obj.memory.buffer,
            _dataPtr + _dataOffset,
            _dataLen
        );
    },

    createBuffer(_wasmId, _deviceId, _size, _usage, _dataPtr, _dataLen) {
        const _mappedAtCreation = _dataLen > 0;

        const _desc = {};
        _desc.size = _size;
        _desc.usage = _usage;
        _desc.mappedAtCreation = _mappedAtCreation;
        const _buffer = _webgpu._devices.get(_deviceId).createBuffer(_desc);

        if (_mappedAtCreation) {
            const _src = new Uint8Array(_main.u8Array(_wasmId, _dataPtr, _dataLen));
            const _dst = new Uint8Array(_buffer.getMappedRange());
            _dst.set(_src);
            _buffer.unmap();
        }

        return _webgpu._buffers.insert(_buffer);
    },

    destroyBuffer(_bufferId) {
        _webgpu._buffers.get(_bufferId).destroy();
        _webgpu._buffers.remove(_bufferId);
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
        const _desc = {};
        _desc.usage = _usage;
        _desc.dimension = _main.getString(_wasmId, _dimensionPtr, _dimensionLen);
        _desc.size = {};
        _desc.size.width = _width;
        _desc.size.height = _height;
        _desc.size.depthOrArrayLayers = _depthOrArrayLayers;
        _desc.format = _main.getString(_wasmId, _formatPtr, _formatLen);
        _desc.mipLevelCount = _mipLevelCount;
        _desc.sampleCount = _sampleCount;
        return _webgpu._textures.insert({
            _obj: _webgpu._devices.get(_deviceId).createTexture(_desc),
            _views: new Objs()
        });
    },

    destroyTexture(_textureId) {
        // texture destroy should be in the api, but it's not available in chrome canary yet...
        _webgpu._textures.remove(_textureId);
    },

    createTextureView(_textureId) {
        const _texture = _webgpu._textures.get(_textureId);
        return (_textureId << 16) | _texture._views.insert(_texture._obj.createView());
    },

    destroyTextureView(_textureViewId) {
        _webgpu._textures.get(_textureViewId >>> 16)._views.remove(_textureViewId & 0x0000FFFF);
    },

    getTextureView(_textureViewId) {
        return _webgpu._textures.get(_textureViewId >>> 16)._views.get(
            _textureViewId & 0x0000FFFF
        );
    },
};
