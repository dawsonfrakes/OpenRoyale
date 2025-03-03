#+build windows
package platform

import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"

d3dobj : struct {
	swapchain: ^dxgi.ISwapChain,
	device: ^d3d11.IDevice,
	ctx: ^d3d11.IDeviceContext,
	swapchain_backbuffer: ^d3d11.ITexture2D,
	backbuffer: ^d3d11.ITexture2D,
	backbuffer_view: ^d3d11.IRenderTargetView,
	depthbuffer_view: ^d3d11.IDepthStencilView,
	depth_state: ^d3d11.IDepthStencilState,
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
		d3dobj.device->CreateDepthStencilState(&desc, &d3dobj.depth_state)
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
