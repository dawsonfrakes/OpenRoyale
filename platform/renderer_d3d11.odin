package platform

import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"

d3dobj: struct {
	swapchain: ^dxgi.ISwapChain,
	device: ^d3d11.IDevice,
	ctx: ^d3d11.IDeviceContext,
	depth_state: ^d3d11.IDepthStencilState,
	using sized: struct {
		backbuffer_texture: ^d3d11.ITexture2D,
		backbuffer_view: ^d3d11.IRenderTargetView,
		depthbuffer_texture: ^d3d11.ITexture2D,
		depthbuffer_view: ^d3d11.IDepthStencilView,
	},
}

d3d11_init :: proc() {
	error: {
		hr: w.HRESULT = ---

		{ // create device, swapchain, device context
			desc: dxgi.SWAP_CHAIN_DESC
			desc.BufferDesc.Format = .R16G16B16A16_FLOAT
			desc.SampleDesc.Count = 1
			desc.BufferCount = 2
			desc.BufferUsage = {.RENDER_TARGET_OUTPUT}
			desc.OutputWindow = platform_hwnd
			desc.Windowed = true
			desc.SwapEffect = .FLIP_DISCARD
			desc.Flags = {.ALLOW_MODE_SWITCH}
			hr = d3d11.CreateDeviceAndSwapChain(nil, .HARDWARE, nil, {.DEBUG} when ODIN_DEBUG else {}, nil, 0,
				d3d11.SDK_VERSION, &desc, &d3dobj.swapchain, &d3dobj.device, nil, &d3dobj.ctx)
			if w.FAILED(hr) do break error
		}

		{ // disable alt-enter
			dxgi_device: ^dxgi.IDevice
			if w.SUCCEEDED(d3dobj.swapchain->GetDevice(dxgi.IDevice_UUID, cast(^rawptr) &dxgi_device)) {
				dxgi_adapter: ^dxgi.IAdapter
				if w.SUCCEEDED(dxgi_device->GetAdapter(&dxgi_adapter)) {
					dxgi_factory: ^dxgi.IFactory
					if w.SUCCEEDED(dxgi_adapter->GetParent(dxgi.IFactory_UUID, cast(^rawptr) &dxgi_factory)) {
						dxgi_factory->MakeWindowAssociation(platform_hwnd, {.NO_ALT_ENTER})
						dxgi_factory->Release()
					}
					dxgi_adapter->Release()
				}
				dxgi_device->Release()
			}
		}

		return
	}
	renderer_switch_api(.NONE)
}

d3d11_deinit :: proc() {
	if d3dobj.swapchain != nil do d3dobj.swapchain->Release()
	if d3dobj.device != nil do d3dobj.device->Release()
	if d3dobj.ctx != nil do d3dobj.ctx->Release()
	if d3dobj.depth_state != nil do d3dobj.depth_state->Release()
	d3dobj = {}
}

d3d11_resize :: proc() {
	error: {
		hr: w.HRESULT = ---

		if d3dobj.backbuffer_texture != nil do d3dobj.backbuffer_texture->Release()
		if d3dobj.backbuffer_view != nil do d3dobj.backbuffer_view->Release()
		if d3dobj.depthbuffer_texture != nil do d3dobj.depthbuffer_texture->Release()
		if d3dobj.depthbuffer_view != nil do d3dobj.depthbuffer_view->Release()
		d3dobj.sized = {}

		{ // create backbuffer texture
			desc: d3d11.TEXTURE2D_DESC
			desc.Width = u32(platform_size.x)
			desc.Height = u32(platform_size.y)
			desc.MipLevels = 1
			desc.ArraySize = 1
			desc.Format = .R16G16B16A16_FLOAT
			desc.SampleDesc.Count = 4
			desc.Usage = .DEFAULT
			desc.BindFlags = {.RENDER_TARGET}
			hr = d3dobj.device->CreateTexture2D(&desc, nil, &d3dobj.backbuffer_texture)
			if w.FAILED(hr) do break error
		}

		{ // create backbuffer view
			hr = d3dobj.device->CreateRenderTargetView(d3dobj.backbuffer_texture, nil, &d3dobj.backbuffer_view)
			if w.FAILED(hr) do break error
		}

		{ // create depth state
			desc: d3d11.DEPTH_STENCIL_DESC
			desc.DepthEnable = true
			desc.DepthWriteMask = .ALL
			desc.DepthFunc = .GREATER_EQUAL
			hr = d3dobj.device->CreateDepthStencilState(&desc, &d3dobj.depth_state)
			if w.FAILED(hr) do break error
		}

		{ // create depthbuffer texture
			desc: d3d11.TEXTURE2D_DESC
			desc.Width = u32(platform_size.x)
			desc.Height = u32(platform_size.y)
			desc.MipLevels = 1
			desc.ArraySize = 1
			desc.Format = .D32_FLOAT
			desc.SampleDesc.Count = 4
			desc.Usage = .DEFAULT
			desc.BindFlags = {.DEPTH_STENCIL}
			hr = d3dobj.device->CreateTexture2D(&desc, nil, &d3dobj.depthbuffer_texture)
			if w.FAILED(hr) do break error
		}

		{ // create depthbuffer view
			hr = d3dobj.device->CreateDepthStencilView(d3dobj.depthbuffer_texture, nil, &d3dobj.depthbuffer_view)
			if w.FAILED(hr) do break error
		}

		return
	}
	renderer_switch_api(.NONE)
}

d3d11_present :: proc() {
	error: {
		hr: w.HRESULT = ---

		swapchain_backbuffer_texture: ^d3d11.ITexture2D
		hr = d3dobj.swapchain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr) &swapchain_backbuffer_texture)
		if w.FAILED(hr) do break error
		defer swapchain_backbuffer_texture->Release()

		d3dobj.ctx->OMSetRenderTargets(1, &d3dobj.backbuffer_view, d3dobj.depthbuffer_view)
		d3dobj.ctx->OMSetDepthStencilState(d3dobj.depth_state, 0)

		viewport: d3d11.VIEWPORT
		viewport.Width = f32(platform_size.x)
		viewport.Height = f32(platform_size.y)
		viewport.MaxDepth = 1.0
		d3dobj.ctx->RSSetViewports(1, &viewport)

		d3dobj.ctx->IASetPrimitiveTopology(.TRIANGLELIST)

		d3dobj.ctx->ResolveSubresource(swapchain_backbuffer_texture, 0, d3dobj.backbuffer_texture, 0, .R16G16B16A16_FLOAT)

		hr = d3dobj.swapchain->Present(1, {})
		if w.FAILED(hr) do break error

		return
	}
	renderer_switch_api(.NONE)
}

d3d11_clear_color :: proc(color: [4]f32, index: u32) {
	color := color
	d3dobj.ctx->ClearRenderTargetView(d3dobj.backbuffer_view, &color)
}

d3d11_clear_depth :: proc(depth: f32) {
	d3dobj.ctx->ClearDepthStencilView(d3dobj.depthbuffer_view, {.DEPTH}, depth, 0)
}

renderer_d3d11 := Renderer{
	init = d3d11_init,
	deinit = d3d11_deinit,
	resize = d3d11_resize,
	present = d3d11_present,
	procs = {
		clear_color = d3d11_clear_color,
		clear_depth = d3d11_clear_depth,
	},
}
