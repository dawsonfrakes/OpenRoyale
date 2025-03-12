package platform

import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"

d3dobj: struct {
	device: ^d3d11.IDevice,
	swapchain: ^dxgi.ISwapChain,
	ctx: ^d3d11.IDeviceContext,
}

d3d11_renderer := Renderer{
	init = proc() {
		hr: w.HRESULT

		error: {
			{
				desc: dxgi.SWAP_CHAIN_DESC
				desc.BufferDesc.Format = .R16G16B16A16_FLOAT
				desc.SampleDesc.Count = 1
				desc.BufferUsage = {.RENDER_TARGET_OUTPUT}
				desc.BufferCount = 2
				desc.OutputWindow = platform_hwnd
				desc.Windowed = true
				desc.Flags = {.ALLOW_MODE_SWITCH}
				hr = d3d11.CreateDeviceAndSwapChain(nil, .HARDWARE, nil, {.DEBUG} when ODIN_DEBUG else {}, nil, 0, d3d11.SDK_VERSION,
					&desc, &d3dobj.swapchain, &d3dobj.device, nil, &d3dobj.ctx)
				if w.FAILED(hr) do break error
			}

			{ // attempt to disable alt-enter (we want to manually switch)
				dxgi_device: ^dxgi.IDevice
				if w.SUCCEEDED(d3dobj.swapchain->GetDevice(dxgi.IDevice_UUID, cast(^rawptr) &dxgi_device)) {
					defer dxgi_device->Release()
					dxgi_adapter: ^dxgi.IAdapter
					if w.SUCCEEDED(dxgi_device->GetAdapter(&dxgi_adapter)) {
						defer dxgi_adapter->Release()
						dxgi_factory: ^dxgi.IFactory
						if w.SUCCEEDED(dxgi_adapter->GetParent(dxgi.IFactory_UUID, cast(^rawptr) &dxgi_factory)) {
							defer dxgi_factory->Release()
							dxgi_factory->MakeWindowAssociation(platform_hwnd, {.NO_ALT_ENTER})
						}
					}
				}
			}

			return
		}
		renderer_switch_api(.NONE)
	},
	deinit = proc() {
		if d3dobj.device != nil do d3dobj.device->Release()
		if d3dobj.swapchain != nil do d3dobj.swapchain->Release()
		if d3dobj.ctx != nil do d3dobj.ctx->Release()
		d3dobj = {}
	},
	resize = proc() {},
	present = proc() {
		error: {
			hr: w.HRESULT

			backbuffer: ^d3d11.ITexture2D
			hr = d3dobj.swapchain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr) &backbuffer)
			if w.FAILED(hr) do break error

			backbuffer_view: ^d3d11.IRenderTargetView
			hr = d3dobj.device->CreateRenderTargetView(backbuffer, nil, &backbuffer_view)
			if w.FAILED(hr) do break error
			defer backbuffer_view->Release()

			d3dobj.ctx->ClearRenderTargetView(backbuffer_view, &{0.6, 0.2, 0.2, 1.0})

			hr = d3dobj.swapchain->Present(1, {})
			if w.FAILED(hr) do break error

			return
		}
		renderer_switch_api(.NONE)
	},
	procs = {
		clear_color = proc(color: [4]f32, index: u32) {},
		clear_depth = proc(depth: f32) {},
	},
}
