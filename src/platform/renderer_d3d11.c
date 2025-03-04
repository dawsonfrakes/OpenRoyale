#include <D3D11.h>

#define D3D_STRINGIFY2(X) #X
#define D3D_STRINGIFY(X) D3D_STRINGIFY2(X)
#define D3D11_CHECK(hr) do { \
	if (FAILED(hr)) { \
		OutputDebugStringA("[D3D11 ERROR]: \""); \
		OutputDebugStringA(__FILE__); \
		OutputDebugStringA(":"); \
		OutputDebugStringA(D3D_STRINGIFY(__LINE__)); \
		OutputDebugStringA("\": "); \
		OutputDebugStringA(#hr); \
		OutputDebugStringA("\n"); \
		goto error; \
	} \
} while (0)

struct {
	IDXGISwapChain* swapchain;
	ID3D11Device* device;
	ID3D11DeviceContext* ctx;
	ID3D11RenderTargetView* backbuffer_view;
} d3d11;

void d3d11_init(void) {
	{
		DXGI_SWAP_CHAIN_DESC desc;
		zero(&desc);
		desc.BufferDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
		desc.SampleDesc.Count = 1;
		desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		desc.BufferCount = 3;
		desc.OutputWindow = platform_hwnd;
		desc.Windowed = true;
		desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
		D3D11_CHECK(D3D11CreateDeviceAndSwapChain(null, D3D_DRIVER_TYPE_HARDWARE, null, DEBUG ? D3D11_CREATE_DEVICE_DEBUG : 0,
			null, 0, D3D11_SDK_VERSION, &desc, &d3d11.swapchain, &d3d11.device, null, &d3d11.ctx));
	}
	return;
error:
	renderer_switch_api(RENDER_API_NONE);
	OutputDebugStringA("Switching to renderer_none because D3D11 initialization failed.\n");
}

void d3d11_deinit(void) {
	if (d3d11.swapchain) IUnknown_Release(d3d11.swapchain);
	if (d3d11.device) IUnknown_Release(d3d11.device);
	if (d3d11.ctx) IUnknown_Release(d3d11.ctx);
	if (d3d11.backbuffer_view) IUnknown_Release(d3d11.backbuffer_view);
	zero(&d3d11);
}

void d3d11_resize(void) {
	ID3D11Texture2D* backbuffer = null;
	{
		if (d3d11.backbuffer_view) IUnknown_Release(d3d11.backbuffer_view);
		D3D11_CHECK(IDXGISwapChain_GetBuffer(d3d11.swapchain, 0, &IID_ID3D11Texture2D, &backbuffer));
		D3D11_CHECK(ID3D11Device_CreateRenderTargetView(d3d11.device, cast(ID3D11Resource*) backbuffer, null, &d3d11.backbuffer_view));
		IUnknown_Release(backbuffer);
	}
	return;
error:
	if (backbuffer) IUnknown_Release(backbuffer);
	renderer_switch_api(RENDER_API_NONE);
	OutputDebugStringA("Switching to renderer_none because D3D11 resize failed.\n");
}

void d3d11_present(void) {
	IDXGISwapChain_Present(d3d11.swapchain, 1, 0);
}

void d3d11_clear_color(f32 color[4], u32 index) {
	assert(index == 0);
	ID3D11DeviceContext_ClearRenderTargetView(d3d11.ctx, d3d11.backbuffer_view, color);
}

Platform_Renderer renderer_d3d11 = {
	d3d11_init,
	d3d11_deinit,
	d3d11_resize,
	d3d11_present,
	{
		d3d11_clear_color,
	},
};
