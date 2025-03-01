#include <D3D11.h>
#include <d3dcompiler.h>

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
	HRESULT hr;
	{
		DXGI_SWAP_CHAIN_DESC desc = {};
		desc.BufferDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
		desc.SampleDesc.Count = 1;
		desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		desc.BufferCount = 2;
		desc.OutputWindow = platform_hwnd;
		desc.Windowed = true;
		desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
		desc.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
		hr = D3D11CreateDeviceAndSwapChain(null, D3D_DRIVER_TYPE_HARDWARE, null, DEBUG ? D3D11_CREATE_DEVICE_DEBUG : 0, null, 0, D3D11_SDK_VERSION,
			&desc, &d3d11.swapchain, &d3d11.device, null, &d3d11.context);
		if (FAILED(hr)) goto error;

		IDXGIDevice* dxgiDevice = null;
		IDXGIAdapter* dxgiAdapter = null;
		IDXGIFactory* dxgiFactory = null;
		if (SUCCEEDED(d3d11.swapchain->GetDevice(__uuidof(IDXGIDevice), (void**) &dxgiDevice))) {
			if (SUCCEEDED(dxgiDevice->GetAdapter(&dxgiAdapter))) {
				if (SUCCEEDED(dxgiAdapter->GetParent(__uuidof(IDXGIFactory), (void**) &dxgiFactory))) {
					dxgiFactory->MakeWindowAssociation(platform_hwnd, DXGI_MWA_NO_ALT_ENTER);
					dxgiFactory->Release();
				}
				dxgiAdapter->Release();
			}
			dxgiDevice->Release();
		}
	}
	return;
error:
	d3d11_deinit();
}

void d3d11_resize() {
	if (!d3d11.swapchain) return;

	d3d11.context->OMSetRenderTargets(0, 0, 0);

	if (d3d11.render_target_view) d3d11.render_target_view->Release();
	d3d11.render_target_view = null;

	d3d11.swapchain->ResizeBuffers(0, 0, 0, DXGI_FORMAT_UNKNOWN, 0);

	ID3D11Resource* backbuffer = null;
	d3d11.swapchain->GetBuffer(0, IID_PPV_ARGS(&backbuffer));
	d3d11.device->CreateRenderTargetView(backbuffer, null, &d3d11.render_target_view);
	backbuffer->Release();
}

void d3d11_fullscreen(bool is_fullscreen) {
	if (d3d11.swapchain && platform_exclusive_fullscreen) d3d11.swapchain->SetFullscreenState(is_fullscreen, null);
}

void d3d11_present() {
	if (!d3d11.context) return;

	d3d11.swapchain->Present(1, 0);
}

void d3d11_clear_color(f32 color[4], u32 index) {
	assert(index == 0); // :temporary
	d3d11.context->ClearRenderTargetView(d3d11.render_target_view, color);
}

void d3d11_clear_depth(f32 depth) {
	assert(0); // :temporary
	d3d11.context->ClearDepthStencilView(null, D3D11_CLEAR_DEPTH, depth, 0);
}
