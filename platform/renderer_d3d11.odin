package platform

import w "core:sys/windows"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"

d3dobj: struct {
	device: ^d3d11.IDevice,
	swapchain: ^dxgi.ISwapChain,
	ctx: ^d3d11.IDeviceContext,
	color0: [4]f32,
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
			defer backbuffer->Release()

			backbuffer_view: ^d3d11.IRenderTargetView
			hr = d3dobj.device->CreateRenderTargetView(backbuffer, nil, &backbuffer_view)
			if w.FAILED(hr) do break error
			defer backbuffer_view->Release()

			d3dobj.ctx->ClearRenderTargetView(backbuffer_view, &d3dobj.color0)

			d3dobj.ctx->IASetPrimitiveTopology(.TRIANGLELIST)
			// d3dobj.ctx->IASetIndexBuffer(rect_index_buffer, .R16_UINT, 0)
			// d3dobj.ctx->IASetVertexBuffers(0, 1, &rect_vertex_buffer, raw_data([]u32{size_of(Rect_Vertex)}), raw_data([]u32{0}))

			// d3dobj.ctx->VSSetShader(rect_vertex_shader, nil, 0)
			// d3dobj.ctx->PSSetShader(rect_pixel_shader, nil, 0)

			viewport: d3d11.VIEWPORT
			viewport.MaxDepth = 1.0
			viewport.Width = f32(platform_size.x)
			viewport.Height = f32(platform_size.y)
			d3dobj.ctx->RSSetViewports(1, &viewport)

			d3dobj.ctx->DrawIndexedInstanced(3, 1, 0, 0, 0)

			hr = d3dobj.swapchain->Present(1, {})
			if w.FAILED(hr) do break error

			return
		}
		renderer_switch_api(.NONE)
	},
	procs = {
		clear_color = proc(color: [4]f32, index: u32) {
			assert(index == 0)
			d3dobj.color0 = color
		},
	},
}
