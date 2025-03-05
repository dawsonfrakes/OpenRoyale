package platform

import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"

d3dobj: struct {
	swapchain: ^dxgi.ISwapChain,
	device: ^d3d11.IDevice,
	ctx: ^d3d11.IDeviceContext,
}

d3d11_init :: proc() {
	error: {
		hr: w.HRESULT = ---

		{
			desc: dxgi.SWAP_CHAIN_DESC
			desc.BufferDesc.Format = .R16G16B16A16_FLOAT
			desc.SampleDesc.Count = 1
			desc.BufferCount = 2
			desc.BufferUsage = {.RENDER_TARGET_OUTPUT}
			desc.OutputWindow = platform_hwnd
			desc.Windowed = true
			desc.SwapEffect = .FLIP_DISCARD
			hr = d3d11.CreateDeviceAndSwapChain(nil, .HARDWARE, nil, {.DEBUG} when ODIN_DEBUG else {}, nil, 0,
				d3d11.SDK_VERSION, &desc, &d3dobj.swapchain, &d3dobj.device, nil, &d3dobj.ctx)
			if w.FAILED(hr) do break error
		}

		return
	}
	renderer_switch_api(.NONE)
}

d3d11_deinit :: proc() {
	if d3dobj.swapchain != nil do d3dobj.swapchain->Release()
	if d3dobj.device != nil do d3dobj.device->Release()
	if d3dobj.ctx != nil do d3dobj.ctx->Release()
	d3dobj = {}
}

d3d11_resize :: proc() {

}

d3d11_present :: proc() {
	d3dobj.swapchain->Present(1, {})
}

d3d11_clear_color :: proc(color: [4]f32, index: u32) {

}

d3d11_clear_depth :: proc(depth: f32) {

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
