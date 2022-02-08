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

    configure(_wasmId, _deviceId, _contextId, _bytesPtr, _bytesLen) {
        const desc = _webgpu.parse(_wasmId, _bytesPtr, _bytesLen);
        desc.device = _webgpu._devices.get(_deviceId);
        _webgpu._contexts.get(_contextId)._obj.configure(
            desc
        );
    },

    requestAdapter(_wasmId, _bytesPtr, _bytesLen) {
        navigator.gpu.requestAdapter(_webgpu.parse(_wasmId, _bytesPtr, _bytesLen))
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

    requestDevice(_wasmId, _adapterId, _bytesPtr, _bytesLen) {
        _webgpu._adapters.get(_adapterId).requestDevice(
            _webgpu.parse(_wasmId, _bytesPtr, _bytesLen)
        )
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

    createBindGroupLayout(_wasmId, _deviceId, _descPtr, _descLen) {
        const _desc = _webgpu.parse(_wasmId, _descPtr, _descLen);
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
        _descPtr,
        _descLen,
    ) {
        const _desc = _webgpu.parse(_wasmId, _descPtr, _descLen);
        _desc.layout = _webgpu._bindGroupLayouts.get(_desc.layout.id);
        for (let i = 0; i < _desc.entries.length; ++i) {
            switch (_desc.entries[i].resource.activeTag) {
                case _BindTypeBuffer:
                    _desc.entries[i].resource.buffer = _webgpu._buffers.get(
                        _desc.entries[i].resource.buffer.id
                    );
                break;
                case _BindTypeSampler:
                    _desc.entries[i].resource = _webgpu._samplers.get(
                        _desc.entries[i].resource.id
                    );
                break;
                case _BindTypeTextureView:
                    _desc.entries[i].resource = _webgpu.getTextureView(
                        _desc.entries[i].resource.id
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

    createPipelineLayout(_wasmId, _deviceId, _descPtr, _descLen) {
        const _desc = _webgpu.parse(_wasmId, _descPtr, _descLen);
        for (let i = 0; i < _desc.bindGroupLayouts.length; ++i) {
            _desc.bindGroupLayouts[i] = _webgpu._bindGroupLayouts.get(
                _desc.bindGroupLayouts[i].id
            );
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
        _bytesPtr,
        _bytesLen,
    ) {
        const _desc = _webgpu.parse(_wasmId, _bytesPtr, _bytesLen);
        _desc.layout = _webgpu._pipelineLayouts.get(_desc.layout.id);
        _desc.vertex.module = _webgpu._shaders.get(_desc.vertex.module.id);
        if (_desc.fragment.module.id !== _InvalidId) {
            _desc.fragment.module = _webgpu._shaders.get(_desc.fragment.module.id);
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
        _bytesPtr,
        _bytesLen
    ) {
        const _desc = _webgpu.parse(_wasmId, _bytesPtr, _bytesLen);
        for (let i = 0; i < _desc.colorAttachments.length; ++i) {
            _desc.colorAttachments[i].view = _webgpu.getTextureView(
                _desc.colorAttachments[i].view.id
            );

            if (_desc.colorAttachments[i].resolveTarget !== undefined) {
                _desc.colorAttachments[i].resolveTarget = _webgpu.getTextureView(
                    _desc.colorAttachments[i].resolveTarget.id
                );
            }
        }

        if (_desc.depthStencilAttachment !== undefined) {
            _desc.depthStencilAttachment.view = _webgpu.getTextureView(
                _desc.depthStencilAttachment.view.id
            );
        }

        if (_desc.occlusionQuerySet !== undefined) {
            _desc.occlusionQuerySet = _webgpu._querySets.get(_desc.occlusionQuerySet.id);
        }

        if (_desc.timestampWrites !== undefined) {
            for (let i = 0; i < _desc.timestampWrites.length; ++i) {
                _desc.timestampWrites[i].querySet = _webgpu._querySets.get(
                    _desc.timestampWrites[i].querySet.id
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

    queueWriteTexture(
        _wasmId,
        _deviceId,
        _textureId,
        _mipLevel,
        _originX,
        _originY,
        _originZ,
        _aspectPtr,
        _aspectLen,
        _dataPtr,
        _dataLen,
        _layoutOffset,
        _layoutBytesPerRow,
        _layoutRowsPerImage,
        _sizeWidth,
        _sizeHeight,
        _sizeDepthOrArrayLayers
    ) {
        const _destination = {};
        _destination.texture = _webgpu._textures.get(_textureId)._obj;
        _destination.mipLevel = _mipLevel;
        _destination.origin = [_originX, _originY, _originZ];
        _destination.aspect = _main.getString(_wasmId, _aspectPtr, _aspectLen);

        const _dataLayout = {};
        _dataLayout.offset = _dataPtr + _layoutOffset;
        _dataLayout.bytesPerRow = _layoutBytesPerRow;
        _dataLayout.rowsPerImage = _layoutRowsPerImage;

        _webgpu._devices.get(_deviceId).queue.writeTexture(
            _destination,
            _main._wasms.get(_wasmId)._obj.memory.buffer,
            _dataLayout,
            [_sizeWidth, _sizeHeight, _sizeDepthOrArrayLayers]
        );
    },

    createBuffer(_wasmId, _deviceId, _descPtr, _descLen, _dataPtr, _dataLen) {
        const _desc = _webgpu.parse(_wasmId, _descPtr, _descLen);
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
        _descPtr,
        _descLen,
    ) {
        const _desc = _webgpu.parse(_wasmId, _descPtr, _descLen);
        return _webgpu._textures.insert({
            _obj: _webgpu._devices.get(_deviceId).createTexture(_desc),
            _views: new Objs()
        });
    },

    destroyTexture(_textureId) {
        // texture destroy should be in the api, but it's not available in chrome canary yet...
        _webgpu._textures.remove(_textureId);
    },

    createSampler(_wasmId, _deviceId, _descPtr, _descLen) {
        return _webgpu._samplers.insert(
            _webgpu._devices.get(_deviceId).createSampler(
                _webgpu.parse(_wasmId, _descPtr, _descLen)
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

    parse(_wasmId, _bytesPtr, _bytesLen) {
        const _data = new DataView(
            _main._wasms.get(_wasmId)._obj.memory.buffer, _bytesPtr, _bytesLen
        );
        const _it = { _index: 0 };
        return _webgpu.parseData(_data, _it);
    },

    parseData(_data, _it) {
        let _value = undefined;
        const _marker = _data.getUint8(_it._index);
        _it._index++;
        switch (_marker) {
            case 98: // b
                _value = _data.getUint8(_it._index) === 1;
                _it._index++;
                break;
            case 105: // i
                _value = _data.getUint32(_it._index, true);
                _it._index += 4;
                break;
            case 102: // f
                _value = _data.getFloat32(_it._index, true);
                _it._index += 4;
                break;
            case 115: // s
                const _slen = _data.getUint32(_it._index, true);
                _it._index += 4;
                _value = new TextDecoder().decode(
                    new Uint8Array(_data.buffer, _data.byteOffset + _it._index, _slen)
                );
                _it._index += _slen;
                break;
            case 97: // a
                const _alen = _data.getUint32(_it._index, true);
                _it._index += 4;
                _value = [];
                for (let _i = 0; _i < _alen; _i++) {
                    _value[_i] = _webgpu.parseData(_data, _it);
                }
                break;
            case 111: // o
                _value = {};
                while (true) {
                    if (_data.getUint8(_it._index) === 101) { // e
                        _it._index++;
                        break;
                    }
                    _value[_webgpu.parseData(_data, _it)] = _webgpu.parseData(_data, _it);
                }
                break;
            case 117: // u
                let _tag = _webgpu.parseData(_data, _it);
                _value = _webgpu.parseData(_data, _it);
                _value.activeTag = _tag;
                break;
            default:
                console.log("invalid marker byte!", _marker);
        }
        return _value;
    },
};
