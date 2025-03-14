#include <D3D11.h>

struct {
	IDXGISwapChain* swapchain;
	ID3D11Device* device;
	ID3D11DeviceContext* ctx;
} d3d11;

void d3d11_init(void) {
	HRESULT hr;

	DXGI_SWAP_CHAIN_DESC desc = {};
	desc.BufferDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
	desc.SampleDesc.Count = 1;
	desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
	desc.BufferCount = 2;
	desc.OutputWindow = platform_hwnd;
	desc.Windowed = true;
	desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
	desc.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
	hr = D3D11CreateDeviceAndSwapChain(null, D3D_DRIVER_TYPE_HARDWARE, null, DEBUG ? D3D11_CREATE_DEVICE_DEBUG : 0, null, 0,
		D3D11_SDK_VERSION, &desc, &d3d11.swapchain, &d3d11.device, null, &d3d11.ctx);
	if (FAILED(hr)) goto error;

	return;
error:
	;
}

void d3d11_deinit(void) {
	if (d3d11.swapchain) d3d11.swapchain->Release();
	if (d3d11.device) d3d11.device->Release();
	if (d3d11.ctx) d3d11.ctx->Release();
	d3d11 = {};
}

void d3d11_resize(void) {

}

void d3d11_present(void) {
	d3d11.swapchain->Present(1, 0);
}
