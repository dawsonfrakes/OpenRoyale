package platform

import "../game"
import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"
import "vendor:directx/d3d_compiler"

Rect_Vertex :: struct {
	position: [2]f32,
}

Rect_Instance :: struct #align(16) {
	offset: [3]f32,
	scale: [2]f32,
	color: [4]f32,
	texcoords: [2][2]f32,
	rotation: f32,
	texture_index: u32,
}

rect_indices := []u16{0, 1, 2, 2, 3, 0}
rect_vertices := []Rect_Vertex{
	{-0.5},
	{{-0.5, 0.5}},
	{0.5},
	{{0.5, -0.5}}
}
rect_instances: [dynamic]Rect_Instance

@private
d3dobj: struct {
	swapchain: ^dxgi.ISwapChain,
	device: ^d3d11.IDevice,
	ctx: ^d3d11.IDeviceContext,

	rect_index_buffer: ^d3d11.IBuffer,
	rect_vertex_buffer: ^d3d11.IBuffer,
	rect_instance_buffer: ^d3d11.IBuffer,
	rect_input_layout: ^d3d11.IInputLayout,
	rect_vertex_shader: ^d3d11.IVertexShader,
	rect_pixel_shader: ^d3d11.IPixelShader,

	color0: [4]f32,
}

d3d11_renderer := Renderer{
	init = proc() {
		error: {
			hr: w.HRESULT = ---

			{
				desc: dxgi.SWAP_CHAIN_DESC
				desc.BufferDesc.Format = .R16G16B16A16_FLOAT
				desc.SampleDesc.Count = 1
				desc.BufferUsage = {.RENDER_TARGET_OUTPUT}
				desc.BufferCount = 2
				desc.OutputWindow = platform_hwnd
				desc.Windowed = true
				desc.SwapEffect = .FLIP_DISCARD
				desc.Flags = {.ALLOW_MODE_SWITCH}
				hr = d3d11.CreateDeviceAndSwapChain(nil, .HARDWARE, nil, {.DEBUG} when ODIN_DEBUG else {}, nil, 0,
					d3d11.SDK_VERSION, &desc, &d3dobj.swapchain, &d3dobj.device, nil, &d3dobj.ctx)
				if w.FAILED(hr) do break error
			}

			{
				dxgi_device: ^dxgi.IDevice = ---
				if w.SUCCEEDED(d3dobj.swapchain->GetDevice(dxgi.IDevice_UUID, cast(^rawptr) &dxgi_device)) {
					defer dxgi_device->Release()
					dxgi_adapter: ^dxgi.IAdapter = ---
					if w.SUCCEEDED(dxgi_device->GetAdapter(&dxgi_adapter)) {
						defer dxgi_adapter->Release()
						dxgi_factory: ^dxgi.IFactory = ---
						if w.SUCCEEDED(dxgi_adapter->GetParent(dxgi.IFactory_UUID, cast(^rawptr) &dxgi_factory)) {
							defer dxgi_factory->Release()
							dxgi_factory->MakeWindowAssociation(platform_hwnd, {.NO_ALT_ENTER})
						}
					}
				}
			}

			{
				desc: d3d11.BUFFER_DESC
				desc.ByteWidth = u32(len(rect_indices) * size_of(u16))
				desc.Usage = .DEFAULT
				desc.BindFlags = {.INDEX_BUFFER}
				desc.StructureByteStride = size_of(u16)
				sr: d3d11.SUBRESOURCE_DATA
				sr.pSysMem = raw_data(rect_indices)
				hr = d3dobj.device->CreateBuffer(&desc, &sr, &d3dobj.rect_index_buffer)
				if w.FAILED(hr) do break error
			}

			{
				desc: d3d11.BUFFER_DESC
				desc.ByteWidth = u32(len(rect_vertices) * size_of(Rect_Vertex))
				desc.Usage = .DEFAULT
				desc.BindFlags = {.VERTEX_BUFFER}
				desc.StructureByteStride = size_of(Rect_Vertex)
				sr: d3d11.SUBRESOURCE_DATA
				sr.pSysMem = raw_data(rect_vertices)
				hr = d3dobj.device->CreateBuffer(&desc, &sr, &d3dobj.rect_vertex_buffer)
				if w.FAILED(hr) do break error
			}

			{
				desc: d3d11.BUFFER_DESC
				desc.ByteWidth = u32(1024 * size_of(Rect_Instance))
				desc.Usage = .DYNAMIC
				desc.BindFlags = {.VERTEX_BUFFER}
				desc.CPUAccessFlags = {.WRITE}
				desc.StructureByteStride = size_of(Rect_Instance)
				hr = d3dobj.device->CreateBuffer(&desc, nil, &d3dobj.rect_instance_buffer)
				if w.FAILED(hr) do break error
			}

			{
				vsrc: cstring = `
				struct VSInput {
					uint vertex_id : SV_VertexID;
					float2 position : POSITION;
					float3 offset : OFFSET;
					float3 scale : SCALE;
					float4 color : COLOR;
					float4 texcoords : TEXCOORDS;
				};

				struct VSOutput {
					float4 color : COLOR;
					float2 texcoord : TEXCOORD;
					float4 position : SV_Position;
				};

				VSOutput main(VSInput input) {
					VSOutput result;
					result.position = float4(input.position * input.scale + input.offset, 0.0, 1.0);
					result.color = input.color;
					result.texcoord = float2(lerp(input.texcoords.x, input.texcoords.z, float(input.vertex_id / 2 == 1)), lerp(input.texcoords.y, input.texcoords.w, float((input.vertex_id + 1) / 2 == 1)));
					return result;
				}
				`
				blob: ^d3d11.IBlob = ---
				hr = d3d_compiler.Compile(cast([^]u8) vsrc, len(vsrc), nil, nil, nil, "main", "vs_5_0", 0, 0, &blob, nil)
				if w.FAILED(hr) do break error
				defer blob->Release()

				hr = d3dobj.device->CreateVertexShader(blob->GetBufferPointer(), blob->GetBufferSize(), nil, &d3dobj.rect_vertex_shader)
				if w.FAILED(hr) do break error

				descs := []d3d11.INPUT_ELEMENT_DESC{
					{"POSITION", 0, .R32G32_FLOAT, 0, u32(offset_of(Rect_Vertex, position)), .VERTEX_DATA, 0},
					{"OFFSET", 0, .R32G32B32_FLOAT, 1, u32(offset_of(Rect_Instance, offset)), .INSTANCE_DATA, 1},
					{"SCALE", 0, .R32G32_FLOAT, 1, u32(offset_of(Rect_Instance, scale)), .INSTANCE_DATA, 1},
					{"COLOR", 0, .R32G32B32A32_FLOAT, 1, u32(offset_of(Rect_Instance, color)), .INSTANCE_DATA, 1},
					{"TEXCOORDS", 0, .R32G32B32A32_FLOAT, 1, u32(offset_of(Rect_Instance, texcoords)), .INSTANCE_DATA, 1},
				}
				hr = d3dobj.device->CreateInputLayout(raw_data(descs), u32(len(descs)), blob->GetBufferPointer(), blob->GetBufferSize(), &d3dobj.rect_input_layout)
				if w.FAILED(hr) do break error
			}

			{
				psrc: cstring = `
				float4 main(float4 color : COLOR, float2 texcoord : TEXCOORD) : SV_Target {
					return float4(texcoord, 0.0, 1.0) * color;
				}
				`
				blob: ^d3d11.IBlob = ---
				hr = d3d_compiler.Compile(cast([^]u8) psrc, len(psrc), nil, nil, nil, "main", "ps_5_0", 0, 0, &blob, nil)
				if w.FAILED(hr) do break error
				defer blob->Release()

				hr = d3dobj.device->CreatePixelShader(blob->GetBufferPointer(), blob->GetBufferSize(), nil, &d3dobj.rect_pixel_shader)
				if w.FAILED(hr) do break error
			}

			return
		}
		renderer_switch_api(.NONE)
	},
	deinit = proc() {
		if d3dobj.swapchain != nil do d3dobj.swapchain->Release()
		if d3dobj.device != nil do d3dobj.device->Release()
		if d3dobj.ctx != nil do d3dobj.ctx->Release()

		if d3dobj.rect_index_buffer != nil do d3dobj.rect_index_buffer->Release()
		if d3dobj.rect_vertex_buffer != nil do d3dobj.rect_vertex_buffer->Release()
		if d3dobj.rect_instance_buffer != nil do d3dobj.rect_instance_buffer->Release()
		if d3dobj.rect_input_layout != nil do d3dobj.rect_input_layout->Release()
		if d3dobj.rect_vertex_shader != nil do d3dobj.rect_vertex_shader->Release()
		if d3dobj.rect_pixel_shader != nil do d3dobj.rect_pixel_shader->Release()

		d3dobj = {}
	},
	resize = proc() {
		d3dobj.swapchain->ResizeBuffers(0, 0, 0, .UNKNOWN, {})
	},
	present = proc() {
		error: {
			hr: w.HRESULT = ---

			{
				mapping: d3d11.MAPPED_SUBRESOURCE = ---
				hr = d3dobj.ctx->Map(d3dobj.rect_instance_buffer, 0, .WRITE_DISCARD, {}, &mapping)
				if w.FAILED(hr) do break error
				copy(([^]Rect_Instance)(mapping.pData)[:len(rect_instances)], rect_instances[:])
				d3dobj.ctx->Unmap(d3dobj.rect_instance_buffer, 0)
			}
			defer clear(&rect_instances)

			backbuffer: ^d3d11.ITexture2D = ---
			hr = d3dobj.swapchain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr) &backbuffer)
			if w.FAILED(hr) do break error
			defer backbuffer->Release()

			backbuffer_view: ^d3d11.IRenderTargetView = ---
			hr = d3dobj.device->CreateRenderTargetView(backbuffer, nil, &backbuffer_view)
			if w.FAILED(hr) do break error
			defer backbuffer_view->Release()

			d3dobj.ctx->ClearRenderTargetView(backbuffer_view, &d3dobj.color0)

			d3dobj.ctx->OMSetRenderTargets(1, &backbuffer_view, nil)

			d3dobj.ctx->IASetIndexBuffer(d3dobj.rect_index_buffer, .R16_UINT, 0)
			vertex_buffers := []^d3d11.IBuffer{d3dobj.rect_vertex_buffer, d3dobj.rect_instance_buffer}
			vertex_strides := []u32{size_of(Rect_Vertex), size_of(Rect_Instance)}
			vertex_offsets := []u32{0, 0}
			d3dobj.ctx->IASetVertexBuffers(0, u32(len(vertex_buffers)), raw_data(vertex_buffers), raw_data(vertex_strides), raw_data(vertex_offsets))
			d3dobj.ctx->IASetInputLayout(d3dobj.rect_input_layout)
			d3dobj.ctx->IASetPrimitiveTopology(.TRIANGLELIST)

			d3dobj.ctx->VSSetShader(d3dobj.rect_vertex_shader, nil, 0)
			d3dobj.ctx->PSSetShader(d3dobj.rect_pixel_shader, nil, 0)

			viewport: d3d11.VIEWPORT
			viewport.MaxDepth = 1.0
			viewport.Width = f32(platform_size.x)
			viewport.Height = f32(platform_size.y)
			d3dobj.ctx->RSSetViewports(1, &viewport)

			d3dobj.ctx->DrawIndexedInstanced(u32(len(rect_indices)), u32(len(rect_instances)), 0, 0, 0)

			hr = d3dobj.swapchain->Present(1, {})
			if w.FAILED(hr) do break error

			return
		}
		renderer_switch_api(.NONE)
	},
	procs = {
		clear_color = proc(color: [4]f32, index: u32 = 0) {
			d3dobj.color0 = color
		},
		rect = proc(position: [2]f32, size: [2]f32, color: [4]f32, texcoords: [2][2]f32, texture: game.Rect_Texture, rotation: f32, z_index: i32) {
			append(&rect_instances, Rect_Instance{
				offset = {position.x / f32(platform_size.x - 1) * 2.0 - 1.0, position.y / f32(platform_size.y - 1) * 2.0 - 1.0, f32(z_index) / 1000.0},
				scale = size / [2]f32{f32(platform_size.x - 1), f32(platform_size.y - 1)} * 2.0,
				color = color,
				texcoords = texcoords,
				texture_index = cast(u32) texture,
				rotation = rotation,
			})
		},
	},
}
