package platform

import w "core:sys/windows"
import "vendor:directx/dxgi"
import "vendor:directx/d3d11"

@private
d3dobj: struct {
	swapchain: ^dxgi.ISwapChain,
	device: ^d3d11.IDevice,
	ctx: ^d3d11.IDeviceContext,

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

			return
		}
		renderer_switch_api(.NONE)
	},
	deinit = proc() {
		if d3dobj.swapchain != nil do d3dobj.swapchain->Release()
		if d3dobj.device != nil do d3dobj.device->Release()
		if d3dobj.ctx != nil do d3dobj.ctx->Release()
		d3dobj = {}
	},
	resize = proc() {},
	present = proc() {
		error: {
			hr: w.HRESULT = ---

			backbuffer: ^d3d11.ITexture2D = ---
			hr = d3dobj.swapchain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr) &backbuffer)
			if w.FAILED(hr) do break error
			defer backbuffer->Release()

			backbuffer_view: ^d3d11.IRenderTargetView = ---
			hr = d3dobj.device->CreateRenderTargetView(backbuffer, nil, &backbuffer_view)
			if w.FAILED(hr) do break error
			defer backbuffer_view->Release()

			d3dobj.ctx->ClearRenderTargetView(backbuffer_view, &d3dobj.color0)

			hr = d3dobj.swapchain->Present(1, {})
			if w.FAILED(hr) do break error

			return
		}
		renderer_switch_api(.NONE)
	},
	procs = {
		clear_color = proc(color: [4]f32, index: u32 = 0) {
			d3dobj.color0 = color
		}
	},
}
