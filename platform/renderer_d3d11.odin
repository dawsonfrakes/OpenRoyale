#+build windows
package platform

import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"
import "vendor:directx/d3d_compiler"

Rect_Index :: u16
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

rect_indices := []Rect_Index{0, 1, 2, 2, 3, 0}
rect_vertices := []Rect_Vertex{
	{position = {-0.5, -0.5}},
	{position = {-0.5, +0.5}},
	{position = {+0.5, +0.5}},
	{position = {+0.5, -0.5}},
}
rect_instances := []Rect_Instance{
	{offset = 0.0, scale = 1.0, color = 1.0, texcoords = {0.0, 1.0}, rotation = 0.0, texture_index = 0},
}

d3dobj : struct {
	swapchain: ^dxgi.ISwapChain,
	device: ^d3d11.IDevice,
	ctx: ^d3d11.IDeviceContext,

	swapchain_backbuffer: ^d3d11.ITexture2D,
	backbuffer: ^d3d11.ITexture2D,
	backbuffer_view: ^d3d11.IRenderTargetView,
	depthbuffer_view: ^d3d11.IDepthStencilView,
	depth_state: ^d3d11.IDepthStencilState,

	rect_index_buffer: ^d3d11.IBuffer,
	rect_vertex_buffer: ^d3d11.IBuffer,
	rect_instance_buffer: ^d3d11.IBuffer,
	rect_input_layout: ^d3d11.IInputLayout,
	rect_vertex_shader: ^d3d11.IVertexShader,
	rect_pixel_shader: ^d3d11.IPixelShader,
}

d3d11_init :: proc() {
	hr: d3d11.HRESULT = ---

	{
		desc: dxgi.SWAP_CHAIN_DESC
		desc.BufferDesc.Format = .R16G16B16A16_FLOAT
		desc.BufferUsage = {.RENDER_TARGET_OUTPUT}
		desc.BufferCount = 3
		desc.OutputWindow = platform_hwnd
		desc.SampleDesc.Count = 1
		desc.SwapEffect = .FLIP_DISCARD
		desc.Windowed = true
		hr = d3d11.CreateDeviceAndSwapChain(nil, .HARDWARE, nil, {.DEBUG} when ODIN_DEBUG else {}, nil, 0, d3d11.SDK_VERSION, &desc, &d3dobj.swapchain, &d3dobj.device, nil, &d3dobj.ctx)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}

	dxgi_device: ^dxgi.IDevice
	dxgi_adapter: ^dxgi.IAdapter
	dxgi_factory: ^dxgi.IFactory
	if w.SUCCEEDED(d3dobj.swapchain->GetDevice(dxgi.IDevice_UUID, cast(^rawptr) &dxgi_device)) {
		if w.SUCCEEDED(dxgi_device->GetAdapter(&dxgi_adapter)) {
			if w.SUCCEEDED(dxgi_adapter->GetParent(dxgi.IFactory_UUID, cast(^rawptr) &dxgi_factory)) {
				dxgi_factory->MakeWindowAssociation(platform_hwnd, {.NO_ALT_ENTER})
				dxgi_factory->Release()
			}
			dxgi_adapter->Release()
		}
		dxgi_device->Release()
	}

	{
		desc: d3d11.DEPTH_STENCIL_DESC
		desc.DepthEnable = true
		desc.DepthWriteMask = .ALL
		desc.DepthFunc = .GREATER_EQUAL
		hr = d3dobj.device->CreateDepthStencilState(&desc, &d3dobj.depth_state)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}

	{
		desc: d3d11.BUFFER_DESC
		desc.ByteWidth = u32(len(rect_indices) * size_of(Rect_Index))
		desc.Usage = .DEFAULT
		desc.BindFlags = {.INDEX_BUFFER}
		desc.StructureByteStride = size_of(Rect_Index)
		sr: d3d11.SUBRESOURCE_DATA
		sr.pSysMem = raw_data(rect_indices)
		hr = d3dobj.device->CreateBuffer(&desc, &sr, &d3dobj.rect_index_buffer)
		if w.FAILED(hr) { d3d11_deinit(); return }
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
		if w.FAILED(hr) { d3d11_deinit(); return }
	}

	{
		desc: d3d11.BUFFER_DESC
		desc.ByteWidth = u32(len(rect_instances) * size_of(Rect_Instance))
		desc.Usage = .DEFAULT
		desc.BindFlags = {.VERTEX_BUFFER}
		desc.StructureByteStride = size_of(Rect_Instance)
		sr: d3d11.SUBRESOURCE_DATA
		sr.pSysMem = raw_data(rect_instances)
		hr = d3dobj.device->CreateBuffer(&desc, &sr, &d3dobj.rect_instance_buffer)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}

	{
		src := `
		float4 main(float2 position : POSITION) : SV_Position {
			return float4(position, 0.0, 1.0);
		}
		`
		blob: ^d3d11.IBlob
		hr = d3d_compiler.Compile(raw_data(src), len(src), nil, nil, nil, "main", "vs_5_0", 0, 0, &blob, nil)
		if w.FAILED(hr) { d3d11_deinit(); return }
		defer blob->Release()

		hr = d3dobj.device->CreateVertexShader(blob->GetBufferPointer(), blob->GetBufferSize(), nil, &d3dobj.rect_vertex_shader)
		if w.FAILED(hr) { d3d11_deinit(); return }

		descs := []d3d11.INPUT_ELEMENT_DESC{
			{SemanticName = "POSITION", SemanticIndex = 0, Format = .R32G32_FLOAT, InputSlot = 0, AlignedByteOffset = u32(offset_of(Rect_Vertex, position)), InputSlotClass = .VERTEX_DATA, InstanceDataStepRate = 0},
		}
		hr = d3dobj.device->CreateInputLayout(raw_data(descs), u32(len(descs)), blob->GetBufferPointer(), blob->GetBufferSize(), &d3dobj.rect_input_layout)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}

	{
		src := `
		float4 main() : SV_Target {
			return float4(1.0, 1.0, 0.0, 1.0);
		}
		`
		blob: ^d3d11.IBlob
		hr = d3d_compiler.Compile(raw_data(src), len(src), nil, nil, nil, "main", "ps_5_0", 0, 0, &blob, nil)
		if w.FAILED(hr) { d3d11_deinit(); return }
		defer blob->Release()

		hr = d3dobj.device->CreatePixelShader(blob->GetBufferPointer(), blob->GetBufferSize(), nil, &d3dobj.rect_pixel_shader)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}
}

d3d11_deinit :: proc() {
	if d3dobj.ctx != nil do d3dobj.ctx->Release()
	if d3dobj.device != nil do d3dobj.device->Release()
	if d3dobj.swapchain != nil do d3dobj.swapchain->Release()
	if d3dobj.swapchain_backbuffer != nil do d3dobj.swapchain_backbuffer->Release()
	if d3dobj.backbuffer != nil do d3dobj.backbuffer->Release()
	if d3dobj.backbuffer_view != nil do d3dobj.backbuffer_view->Release()
	if d3dobj.depthbuffer_view != nil do d3dobj.depthbuffer_view->Release()
	if d3dobj.depth_state != nil do d3dobj.depth_state->Release()
	if d3dobj.rect_index_buffer != nil do d3dobj.rect_index_buffer->Release()
	if d3dobj.rect_vertex_buffer != nil do d3dobj.rect_vertex_buffer->Release()
	if d3dobj.rect_instance_buffer != nil do d3dobj.rect_instance_buffer->Release()
	if d3dobj.rect_input_layout != nil do d3dobj.rect_input_layout->Release()
	if d3dobj.rect_vertex_shader != nil do d3dobj.rect_vertex_shader->Release()
	if d3dobj.rect_pixel_shader != nil do d3dobj.rect_pixel_shader->Release()
	d3dobj = {}
}

d3d11_resize :: proc() {
	if d3dobj.swapchain == nil do return

	hr: d3d11.HRESULT = ---

	if d3dobj.swapchain_backbuffer != nil do d3dobj.swapchain_backbuffer->Release()
	d3dobj.swapchain_backbuffer = nil
	if d3dobj.backbuffer != nil do d3dobj.backbuffer->Release()
	d3dobj.backbuffer = nil
	if d3dobj.backbuffer_view != nil do d3dobj.backbuffer_view->Release()
	d3dobj.backbuffer_view = nil
	if d3dobj.depthbuffer_view != nil do d3dobj.depthbuffer_view->Release()
	d3dobj.depthbuffer_view = nil

	hr = d3dobj.swapchain->ResizeBuffers(0, 0, 0, {}, {})
	if w.FAILED(hr) { d3d11_deinit(); return }

	hr = d3dobj.swapchain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr) &d3dobj.swapchain_backbuffer)
	if w.FAILED(hr) { d3d11_deinit(); return }

	{
		desc: d3d11.TEXTURE2D_DESC
		desc.ArraySize = 1
		desc.MipLevels = 1
		desc.BindFlags = {.RENDER_TARGET}
		desc.Format = .R16G16B16A16_FLOAT
		desc.Usage = .DEFAULT
		desc.SampleDesc.Count = 4
		desc.Width = u32(platform_size.x)
		desc.Height = u32(platform_size.y)
		hr = d3dobj.device->CreateTexture2D(&desc, nil, &d3dobj.backbuffer)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}
	hr = d3dobj.device->CreateRenderTargetView(d3dobj.backbuffer, nil, &d3dobj.backbuffer_view)
	if w.FAILED(hr) { d3d11_deinit(); return }

	depth_texture: ^d3d11.ITexture2D
	{
		desc: d3d11.TEXTURE2D_DESC
		desc.ArraySize = 1
		desc.MipLevels = 1
		desc.BindFlags = {.DEPTH_STENCIL}
		desc.Format = .D32_FLOAT
		desc.Usage = .DEFAULT
		desc.SampleDesc.Count = 4
		desc.Width = u32(platform_size.x)
		desc.Height = u32(platform_size.y)
		hr = d3dobj.device->CreateTexture2D(&desc, nil, &depth_texture)
		if w.FAILED(hr) { d3d11_deinit(); return }
	}
	hr = d3dobj.device->CreateDepthStencilView(depth_texture, nil, &d3dobj.depthbuffer_view)
	if w.FAILED(hr) { d3d11_deinit(); return }
	depth_texture->Release()
}

d3d11_present :: proc() {
	if d3dobj.swapchain == nil do return

	d3dobj.ctx->OMSetDepthStencilState(d3dobj.depth_state, 0)
	d3dobj.ctx->OMSetRenderTargets(1, &d3dobj.backbuffer_view, d3dobj.depthbuffer_view)

	vertex_buffers := [](^d3d11.IBuffer){d3dobj.rect_vertex_buffer, d3dobj.rect_instance_buffer}
	vertex_strides := []u32{size_of(Rect_Vertex), size_of(Rect_Instance)}
	vertex_offsets := []u32{0, 0}
	d3dobj.ctx->IASetVertexBuffers(0, 2, raw_data(vertex_buffers), raw_data(vertex_strides), raw_data(vertex_offsets))
	d3dobj.ctx->IASetIndexBuffer(d3dobj.rect_index_buffer, .R16_UINT, 0)
	d3dobj.ctx->IASetInputLayout(d3dobj.rect_input_layout)
	d3dobj.ctx->VSSetShader(d3dobj.rect_vertex_shader, nil, 0)
	d3dobj.ctx->PSSetShader(d3dobj.rect_pixel_shader, nil, 0)
	d3dobj.ctx->IASetPrimitiveTopology(.TRIANGLELIST)
	viewport: d3d11.VIEWPORT
	viewport.Width = f32(platform_size.x)
	viewport.Height = f32(platform_size.y)
	viewport.MaxDepth = 1.0
	d3dobj.ctx->RSSetViewports(1, &viewport)

	d3dobj.ctx->DrawIndexedInstanced(u32(len(rect_indices)), u32(len(rect_instances)), 0, 0, 0)

	d3dobj.ctx->ResolveSubresource(d3dobj.swapchain_backbuffer, 0, d3dobj.backbuffer, 0, .R16G16B16A16_FLOAT)
	d3dobj.swapchain->Present(1, {})
}

d3d11_clear_color :: proc(color: [4]f32, index: u32) {
	color := color
	assert(index == 0)
	d3dobj.ctx->ClearRenderTargetView(d3dobj.backbuffer_view, &color)
}

d3d11_clear_depth :: proc(depth: f32) {
	d3dobj.ctx->ClearDepthStencilView(d3dobj.depthbuffer_view, {.DEPTH}, depth, 0)
}
