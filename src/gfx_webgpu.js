const _InvalidId = 0;
const _DefaultDescId = 0;
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
    _descs: new Objs(),

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

    configure(_wasmId, _deviceId, _contextId, _descId) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        _desc.device = _webgpu._devices.get(_deviceId);
        _webgpu._contexts.get(_contextId)._obj.configure(_desc);
    },

    requestAdapter(_wasmId, _descId) {
        navigator.gpu.requestAdapter(_webgpu.getDesc(_descId)._obj)
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

    requestDevice(_wasmId, _adapterId, _descId) {
        _webgpu._adapters.get(_adapterId).requestDevice(_webgpu.getDesc(_descId)._obj)
            .then(_device => {
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

    createBindGroupLayout(_wasmId, _deviceId, _descId) {
        const _desc = _webgpu.getDesc(_descId)._obj;
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
        _descId,
    ) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        _desc.layout = _webgpu._bindGroupLayouts.get(_desc.layout);
        for (let i = 0; i < _desc.entries.length; ++i) {
            switch (_desc.entries[i].resourceType) {
                case _BindTypeBuffer:
                    _desc.entries[i].resource.buffer = _webgpu._buffers.get(
                        _desc.entries[i].resource.buffer
                    );
                break;
                case _BindTypeSampler:
                    _desc.entries[i].resource = _webgpu._samplers.get(
                        _desc.entries[i].resource
                    );
                break;
                case _BindTypeTextureView:
                    _desc.entries[i].resource = _webgpu.getTextureView(
                        _desc.entries[i].resource
                    );
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

    createPipelineLayout(_wasmId, _deviceId, _descId) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        for (let i = 0; i < _desc.bindGroupLayouts.length; ++i) {
            _desc.bindGroupLayouts[i] = _webgpu._bindGroupLayouts.get(_desc.bindGroupLayouts[i]);
        }
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
        _descId,
    ) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        _desc.layout = _webgpu._pipelineLayouts.get(_desc.layout);
        _desc.vertex.module = _webgpu._shaders.get(_desc.vertex.module);
        if (_desc.fragment !== undefined) {
            _desc.fragment.module = _webgpu._shaders.get(_desc.fragment.module);
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
        _descId,
    ) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        for (let i = 0; i < _desc.colorAttachments.length; ++i) {
            _desc.colorAttachments[i].view = _webgpu.getTextureView(
                _desc.colorAttachments[i].view
            );

            if (_desc.colorAttachments[i].resolveTarget !== undefined) {
                _desc.colorAttachments[i].resolveTarget = _webgpu.getTextureView(
                    _desc.colorAttachments[i].resolveTarget
                );
            }
        }

        if (_desc.depthStencilAttachment !== undefined) {
            _desc.depthStencilAttachment.view = _webgpu.getTextureView(
                _desc.depthStencilAttachment.view
            );
        }

        if (_desc.occlusionQuerySet !== undefined) {
            _desc.occlusionQuerySet = _webgpu._querySets.get(_desc.occlusionQuerySet);
        }

        if (_desc.timestampWrites !== undefined) {
            for (let i = 0; i < _desc.timestampWrites.length; ++i) {
                _desc.timestampWrites[i].querySet = _webgpu._querySets.get(
                    _desc.timestampWrites[i].querySet
                );
            }
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
        _webgpu._renderPasses.get(_renderPassId).end();
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

    queueWriteTexture(
        _wasmId,
        _deviceId,
        _destinationId,
        _dataPtr,
        _dataLen,
        _dataLayoutId,
        _sizeWidth,
        _sizeHeight,
        _sizeDepthOrArrayLayers
    ) {
        const _destination = _webgpu.getDesc(_destinationId)._obj;
        _destination.texture = _webgpu._textures.get(_destination.texture)._obj;
        const _dataLayout = _webgpu.getDesc(_dataLayoutId)._obj;
        if (_dataLayout.offset === undefined) {
            _dataLayout.offset = _dataPtr;
        } else {
            _dataLayout.offset += _dataPtr;
        }
        _webgpu._devices.get(_deviceId).queue.writeTexture(
            _destination,
            _main._wasms.get(_wasmId)._obj.memory.buffer,
            _dataLayout,
            [_sizeWidth, _sizeHeight, _sizeDepthOrArrayLayers]
        );
    },

    createBuffer(_wasmId, _deviceId, _descId, _dataPtr, _dataLen) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        _desc.mappedAtCreation = _dataLen > 0;
        const _buffer = _webgpu._devices.get(_deviceId).createBuffer(_desc);

        if (_desc.mappedAtCreation) {
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
        _descId,
    ) {
        const _desc = _webgpu.getDesc(_descId)._obj;
        return _webgpu._textures.insert({
            _obj: _webgpu._devices.get(_deviceId).createTexture(_desc),
            _views: new Objs()
        });
    },

    destroyTexture(_textureId) {
        // texture destroy should be in the api, but it's not available in chrome canary yet...
        _webgpu._textures.remove(_textureId);
    },

    createSampler(_wasmId, _deviceId, _descId) {
        return _webgpu._samplers.insert(
            _webgpu._devices.get(_deviceId).createSampler(
                _webgpu.getDesc(_descId)
            )
        );
    },

    destroySampler(_samplerId) {
        _webgpu._samplers.remove(_samplerId);
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

    createDesc() {
        return _webgpu._descs.insert({
            _stack: [{ _obj: {}, _field: null, _array: false }],
        });
    },

    destroyDesc(_descId) {
        _webgpu._descs.remove(_descId);
    },

    getDesc(_descId) {
        if (_descId === _DefaultDescId) {
            return { _obj: {} };
        }
        const _desc = _webgpu._descs.get(_descId);
        return _desc._stack[_desc._stack.length - 1];
    },

    setDescField(_wasmId, _descId, _fieldPtr, _fieldLen) {
        _webgpu.getDesc(_descId)._field = _main.getString(_wasmId, _fieldPtr, _fieldLen);
    },

    setDescValue(_descId, _value) {
        const _desc = _webgpu.getDesc(_descId);
        if (_desc._array) {
            _desc._obj[_desc._field].push(_value);
        } else {
            _desc._obj[_desc._field] = _value;
        }
    },

    setDescString(_wasmId, _descId, _valuePtr, _valueLen) {
        _webgpu.setDescValue(_descId, _main.getString(_wasmId, _valuePtr, _valueLen));
    },

    setDescBool(_descId, _value) {
        _webgpu.setDescValue(_descId, !!_value);
    },

    setDescU32(_descId, _value) {
        _webgpu.setDescValue(_descId, _value);
    },

    setDescI32(_descId, _value) {
        _webgpu.setDescValue(_descId, _value);
    },

    setDescF32(_descId, _value) {
        _webgpu.setDescValue(_descId, _value);
    },

    beginDescArray(_descId) {
        const _desc = _webgpu.getDesc(_descId);
        _desc._obj[_desc._field] = [];
        _desc._array = true;
    },

    endDescArray(_descId) {
        _webgpu.getDesc(_descId)._array = false;
    },

    beginDescChild(_descId) {
        _webgpu._descs.get(_descId)._stack.push({ _obj: {}, _field: null, _array: false });
    },

    endDescChild(_descId) {
        const _desc = _webgpu._descs.get(_descId);
        const _obj = _desc._stack[_desc._stack.length - 1]._obj;
        _desc._stack.pop();
        _webgpu.setDescValue(_descId, _obj);
    }
};
