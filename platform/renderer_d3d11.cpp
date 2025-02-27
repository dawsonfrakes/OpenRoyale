#include <D3D11.h>
#include <dxgi.h>

struct {
	IDXGISwapChain* swapchain;
	ID3D11Device* device;
	ID3D11DeviceContext* context;
	ID3D11RenderTargetView* render_target_view;
} d3d11;

void d3d11_deinit() {
	if (d3d11.render_target_view) d3d11.render_target_view->Release();
	if (d3d11.swapchain) d3d11.swapchain->Release();
	if (d3d11.context) d3d11.context->Release();
	if (d3d11.device) d3d11.device->Release();
	d3d11 = {};
}

void d3d11_init() {
	{
		HRESULT hr;
		DXGI_SWAP_CHAIN_DESC sd = {};
		sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
		sd.SampleDesc.Count = 1;
		sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		sd.BufferCount = 1;
		sd.OutputWindow = platform_hwnd;
		sd.Windowed = true;
		hr = D3D11CreateDeviceAndSwapChain(null, D3D_DRIVER_TYPE_HARDWARE, null, 0, null, 0, D3D11_SDK_VERSION,
			&sd, &d3d11.swapchain, &d3d11.device, null, &d3d11.context);
		if (FAILED(hr)) goto error;

		ID3D11Resource* backbuffer = null;
		d3d11.swapchain->GetBuffer(0, IID_PPV_ARGS(&backbuffer));
		d3d11.device->CreateRenderTargetView(backbuffer, null, &d3d11.render_target_view);
		backbuffer->Release();
	}
	return;
error:
	d3d11_deinit();
}

void d3d11_resize() {

}

void d3d11_present() {
	f32 color[] = {0.6f, 0.2f, 0.2f, 1.0f};
	d3d11.context->ClearRenderTargetView(d3d11.render_target_view, color);
	d3d11.swapchain->Present(1, 0);
}
