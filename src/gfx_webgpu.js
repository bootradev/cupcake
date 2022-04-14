const _InvalidId = 0;
const _DefaultDescId = 0;
const _WholeSize = 0xFFFFFFFF;
const _BindTypeBuffer = 0;
const _BindTypeSampler = 1;
const _BindTypeTextureView = 2;

const _webgpu = {
    _descs: new _Objs(),
    _contexts: new _Objs(),
    _contexts: new _Objs(),
    _adapters: new _Objs(),
    _devices: new _Objs(),
    _shaders: new _Objs(),
    _bindGroupLayouts: new _Objs(),
    _bindGroups: new _Objs(),
    _pipelineLayouts: new _Objs(),
    _renderPipelines: new _Objs(),
    _buffers: new _Objs(),
    _textures: new _Objs(),
    _samplers: new _Objs(),
    _commandEncoders: new _Objs(),
    _commandBuffers: new _Objs(),
    _renderPassDescs: new _Objs(),
    _renderPasses: new _Objs(),
    _querySets: new _Objs(),

    createDesc() {
        return _webgpu._descs._insert({
            _stack: [{ _obj: {}, _field: null, _array: false }],
        });
    },

    destroyDesc(_descId) {
        if (_descId != _DefaultDescId) {
            _webgpu._descs._remove(_descId);
        }
    },

    setDescField(_wasmId, _descId, _fieldPtr, _fieldLen) {
        _webgpu._getDesc(_descId)._field = _main._getString(_wasmId, _fieldPtr, _fieldLen);
    },

    setDescString(_wasmId, _descId, _valuePtr, _valueLen) {
        _webgpu._setDescValue(_descId, _main._getString(_wasmId, _valuePtr, _valueLen));
    },

    setDescBool(_descId, _value) {
        _webgpu._setDescValue(_descId, !!_value);
    },

    setDescU32(_descId, _value) {
        _webgpu._setDescValue(_descId, _value);
    },

    setDescI32(_descId, _value) {
        _webgpu._setDescValue(_descId, _value);
    },

    setDescF32(_descId, _value) {
        _webgpu._setDescValue(_descId, _value);
    },

    beginDescArray(_descId) {
        const _desc = _webgpu._getDesc(_descId);
        _desc._obj[_desc._field] = [];
        _desc._array = true;
    },

    endDescArray(_descId) {
        _webgpu._getDesc(_descId)._array = false;
    },

    beginDescChild(_descId) {
        _webgpu._descs._get(_descId)._stack.push({ _obj: {}, _field: null, _array: false });
    },

    endDescChild(_descId) {
        const _desc = _webgpu._descs._get(_descId);
        const _obj = _desc._stack[_desc._stack.length - 1]._obj;
        _desc._stack.pop();
        _webgpu._setDescValue(_descId, _obj);
    },

    _setDescValue(_descId, _value) {
        const _desc = _webgpu._getDesc(_descId);
        if (_desc._array) {
            _desc._obj[_desc._field].push(_value);
        } else {
            _desc._obj[_desc._field] = _value;
        }
    },

    _getDesc(_descId) {
        if (_descId === _DefaultDescId) {
            return { _obj: {} };
        }
        const _desc = _webgpu._descs._get(_descId);
        return _desc._stack[_desc._stack.length - 1];
    },

    createContext(_canvasId) {
        return _webgpu._contexts._insert({
            _obj: _app._canvases._get(_canvasId)._obj.getContext("webgpu"),
            _texId: _webgpu._textures._insert({}),
        });
    },

    destroyContext(_contextId) {
        _webgpu._textures._remove(_webgpu._contexts._get(_contextId)._texId);
        _webgpu._contexts._remove(_contextId);
    },

    getContextCurrentTexture(_contextId) {
        const _context = _webgpu._contexts._get(_contextId);
        _webgpu._textures._set({
            _obj: _context._obj.getCurrentTexture(),
            _views: new _Objs()
        }, _context._texId);
        return _context._texId;
    },

    getPreferredFormat(_wasmId, _contextId, _adapterId) {
        const _format = _webgpu._contexts._get(_contextId)._obj.getPreferredFormat(
            _webgpu._adapters._get(_adapterId)
        );

        // format must be one of the supported context formats:
        if (_format === "bgra8unorm") {
            return 22;
        } else if (_format === "rgba8unorm") {
            return 17;
        } else if (_format === "rgba16float") {
            return 32;
        } else {
            console.log("unexpected preferred format:", _format);
            return -1;
        }
    },

    configure(_wasmId, _deviceId, _contextId, _descId) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        _desc.device = _webgpu._devices._get(_deviceId);
        _webgpu._contexts._get(_contextId)._obj.configure(_desc);
    },

    requestAdapter(_wasmId, _descId) {
        navigator.gpu.requestAdapter(_webgpu._getDesc(_descId)._obj)
            .then(_adapter => {
                _main._wasms._get(_wasmId)._obj.requestAdapterComplete(
                    _webgpu._adapters._insert(_adapter)
                );
            })
            .catch(_err => {
                console.log(_err);
                _main._wasms._get(_wasmId)._obj.requestAdapterComplete(_InvalidId);
            });
    },

    destroyAdapter(_adapterId) {
        _webgpu._adapters._remove(_adapterId);
    },

    requestDevice(_wasmId, _adapterId, _descId) {
        _webgpu._adapters._get(_adapterId).requestDevice(_webgpu._getDesc(_descId)._obj)
            .then(_device => {
                _main._wasms._get(_wasmId)._obj.requestDeviceComplete(
                    _webgpu._devices._insert(_device)
                );
            })
            .catch(_err => {
                console.log(_err);
                _main._wasms._get(_wasmId)._obj.requestDeviceComplete(_InvalidId);
            });
    },

    destroyDevice(_deviceId) {
        // device destroy should be in the api, but it's not available in chrome canary yet...
        _webgpu._devices._remove(_deviceId);
    },

    createShader(_wasmId, _deviceId, _codePtr, _codeLen) {
        const _desc = {};
        _desc.code = _main._getString(_wasmId, _codePtr, _codeLen);
        return _webgpu._shaders._insert(
            _webgpu._devices._get(_deviceId).createShaderModule(_desc)
        );
    },

    destroyShader(_shaderId) {
        _webgpu._shaders._remove(_shaderId);
    },

    checkShaderCompile(_wasmId, _shaderId) {
        _webgpu._shaders._get(_shaderId).compilationInfo()
            .then(_info => {
                let _err = false;
                for (let i = 0; i < _info.messages.length; ++i) {
                    const _msg = _info.messages[i];
                    console.log("line:", _msg.lineNum, "col:", _msg.linePos, _msg.message);
                    _err |= _msg.type == "error";
                }
                _main._wasms._get(_wasmId)._obj.checkShaderCompileComplete(_err);
            });
    },

    createBindGroupLayout(_wasmId, _deviceId, _descId) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        return _webgpu._bindGroupLayouts._insert(
            _webgpu._devices._get(_deviceId).createBindGroupLayout(_desc)
        );
    },

    destroyBindGroupLayout(_bindGroupLayoutId) {
        _webgpu._bindGroupLayouts._remove(_bindGroupLayoutId);
    },

    createBindGroup(
        _wasmId,
        _deviceId,
        _descId,
    ) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        _desc.layout = _webgpu._bindGroupLayouts._get(_desc.layout);
        for (let i = 0; i < _desc.entries.length; ++i) {
            switch (_desc.entries[i].BindingResourceType) {
                case _BindTypeBuffer:
                    _desc.entries[i].resource.buffer = _webgpu._buffers._get(
                        _desc.entries[i].resource.buffer
                    );
                break;
                case _BindTypeSampler:
                    _desc.entries[i].resource = _webgpu._samplers._get(
                        _desc.entries[i].resource
                    );
                break;
                case _BindTypeTextureView:
                    _desc.entries[i].resource = _webgpu._getTextureView(
                        _desc.entries[i].resource
                    );
                break;
            }
        }

        return _webgpu._bindGroups._insert(
            _webgpu._devices._get(_deviceId).createBindGroup(_desc)
        );
    },

    destroyBindGroup(_bindGroupId) {
        _webgpu._bindGroups._remove(_bindGroupId);
    },

    createPipelineLayout(_wasmId, _deviceId, _descId) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        for (let i = 0; i < _desc.bindGroupLayouts.length; ++i) {
            _desc.bindGroupLayouts[i] = _webgpu._bindGroupLayouts._get(_desc.bindGroupLayouts[i]);
        }
        return _webgpu._pipelineLayouts._insert(
            _webgpu._devices._get(_deviceId).createPipelineLayout(_desc)
        );
    },

    destroyPipelineLayout(_pipelineLayoutId) {
        _webgpu._pipelineLayouts._remove(_pipelineLayoutId);
    },

    createRenderPipeline(
        _wasmId,
        _deviceId,
        _descId,
    ) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        if (_desc.layout !== undefined) {
            _desc.layout = _webgpu._pipelineLayouts._get(_desc.layout);
        }
        _desc.vertex.module = _webgpu._shaders._get(_desc.vertex.module);
        if (_desc.fragment !== undefined) {
            _desc.fragment.module = _webgpu._shaders._get(_desc.fragment.module);
        }
        return _webgpu._renderPipelines._insert(
            _webgpu._devices._get(_deviceId).createRenderPipeline(_desc)
        );
    },

    destroyRenderPipeline(_renderPipelineId) {
        _webgpu._renderPipelines._remove(_renderPipelineId);
    },

    createCommandEncoder(_deviceId) {
        return _webgpu._commandEncoders._insert(
            _webgpu._devices._get(_deviceId).createCommandEncoder()
        );
    },

    finishCommandEncoder(_commandEncoderId) {
        const _commandBufferId = _webgpu._commandBuffers._insert(
            _webgpu._commandEncoders._get(_commandEncoderId).finish()
        );
        _webgpu._commandEncoders._remove(_commandEncoderId);
        return _commandBufferId;
    },

    beginRenderPass(
        _wasmId,
        _commandEncoderId,
        _descId,
    ) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        for (let i = 0; i < _desc.colorAttachments.length; ++i) {
            _desc.colorAttachments[i].view = _webgpu._getTextureView(
                _desc.colorAttachments[i].view
            );

            if (_desc.colorAttachments[i].resolveTarget !== undefined) {
                _desc.colorAttachments[i].resolveTarget = _webgpu._getTextureView(
                    _desc.colorAttachments[i].resolveTarget
                );
            }
        }

        if (_desc.depthStencilAttachment !== undefined) {
            _desc.depthStencilAttachment.view = _webgpu._getTextureView(
                _desc.depthStencilAttachment.view
            );
        }

        if (_desc.occlusionQuerySet !== undefined) {
            _desc.occlusionQuerySet = _webgpu._querySets._get(_desc.occlusionQuerySet);
        }

        if (_desc.timestampWrites !== undefined) {
            for (let i = 0; i < _desc.timestampWrites.length; ++i) {
                _desc.timestampWrites[i].querySet = _webgpu._querySets._get(
                    _desc.timestampWrites[i].querySet
                );
            }
        }

        return _webgpu._renderPasses._insert(
            _webgpu._commandEncoders._get(_commandEncoderId).beginRenderPass(_desc)
        );
    },

    setPipeline(_renderPassId, _pipelineId) {
        _webgpu._renderPasses._get(_renderPassId).setPipeline(
            _webgpu._renderPipelines._get(_pipelineId)
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
            _dynamicOffsets = _main._u32Array(_wasmId, _dynamicOffsetsPtr, _dynamicOffsetsLen);
        }
        _webgpu._renderPasses._get(_renderPassId).setBindGroup(
            _groupIndex,
            _webgpu._bindGroups._get(_bindGroupId),
            _dynamicOffsets
        );
    },

    setVertexBuffer(_renderPassId, _slot, _bufferId, _offset, _size) {
        if ((_size >>> 0) === _WholeSize) {
            _size = undefined;
        }

        _webgpu._renderPasses._get(_renderPassId).setVertexBuffer(
            _slot,
            _webgpu._buffers._get(_bufferId),
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

        _webgpu._renderPasses._get(_renderPassId).setIndexBuffer(
            _webgpu._buffers._get(_bufferId),
            _main._getString(_wasmId, _indexFormatPtr, _indexFormatLen),
            _offset,
            _size
        );
    },

    draw(_renderPassId, _vertexCount, _instanceCount, _firstVertex, _firstInstance) {
        _webgpu._renderPasses._get(_renderPassId).draw(
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
        _webgpu._renderPasses._get(_renderPassId).drawIndexed(
            _indexCount,
            _instanceCount,
            _firstIndex,
            _baseVertex,
            _firstInstance
        );
    },

    endRenderPass(_renderPassId) {
        _webgpu._renderPasses._get(_renderPassId).end();
        _webgpu._renderPasses._remove(_renderPassId);
    },

    queueSubmit(_wasmId, _deviceId, _commandBufferId) {
        _webgpu._devices._get(_deviceId).queue.submit(
            [_webgpu._commandBuffers._get(_commandBufferId)]
        );
        _webgpu._commandBuffers._remove(_commandBufferId);
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
        _webgpu._devices._get(_deviceId).queue.writeBuffer(
            _webgpu._buffers._get(_bufferId),
            _bufferOffset,
            _main._wasms._get(_wasmId)._obj.memory.buffer,
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
        const _destination = _webgpu._getDesc(_destinationId)._obj;
        _destination.texture = _webgpu._textures._get(_destination.texture)._obj;
        const _dataLayout = _webgpu._getDesc(_dataLayoutId)._obj;
        if (_dataLayout.offset === undefined) {
            _dataLayout.offset = _dataPtr;
        } else {
            _dataLayout.offset += _dataPtr;
        }
        _webgpu._devices._get(_deviceId).queue.writeTexture(
            _destination,
            _main._wasms._get(_wasmId)._obj.memory.buffer,
            _dataLayout,
            [_sizeWidth, _sizeHeight, _sizeDepthOrArrayLayers]
        );
    },

    createBuffer(_wasmId, _deviceId, _descId, _dataPtr, _dataLen) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        _desc.mappedAtCreation = _dataLen > 0;
        const _buffer = _webgpu._devices._get(_deviceId).createBuffer(_desc);

        if (_desc.mappedAtCreation) {
            const _src = new Uint8Array(_main._u8Array(_wasmId, _dataPtr, _dataLen));
            const _dst = new Uint8Array(_buffer.getMappedRange());
            _dst.set(_src);
            _buffer.unmap();
        }

        return _webgpu._buffers._insert(_buffer);
    },

    destroyBuffer(_bufferId) {
        _webgpu._buffers._get(_bufferId).destroy();
        _webgpu._buffers._remove(_bufferId);
    },

    createTexture(
        _wasmId,
        _deviceId,
        _descId,
    ) {
        const _desc = _webgpu._getDesc(_descId)._obj;
        return _webgpu._textures._insert({
            _obj: _webgpu._devices._get(_deviceId).createTexture(_desc),
            _views: new _Objs()
        });
    },

    destroyTexture(_textureId) {
        // texture destroy should be in the api, but it's not available in chrome canary yet...
        _webgpu._textures._remove(_textureId);
    },

    createSampler(_wasmId, _deviceId, _descId) {
        return _webgpu._samplers._insert(
            _webgpu._devices._get(_deviceId).createSampler(_webgpu._getDesc(_descId))
        );
    },

    destroySampler(_samplerId) {
        _webgpu._samplers._remove(_samplerId);
    },

    createTextureView(_textureId) {
        const _texture = _webgpu._textures._get(_textureId);
        return (_textureId << 16) | _texture._views._insert(_texture._obj.createView());
    },

    destroyTextureView(_textureViewId) {
        _webgpu._textures._get(_textureViewId >>> 16)._views._remove(_textureViewId & 0x0000FFFF);
    },

    _getTextureView(_textureViewId) {
        return _webgpu._textures._get(_textureViewId >>> 16)._views._get(
            _textureViewId & 0x0000FFFF
        );
    }
};
