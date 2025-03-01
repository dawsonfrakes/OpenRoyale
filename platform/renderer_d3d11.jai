d3d11_renderer :: struct {
	init :: d3d11_init;
	deinit :: d3d11_deinit;
	resize :: d3d11_resize;
	present :: d3d11_present;
}

#scope_file

#import "d3d11";
#import "dxgi";

d3d11: struct {
	swapchain: *IDXGISwapChain;
	device: *ID3D11Device;
	ctx: *ID3D11DeviceContext;
	backbuffer_view: *ID3D11RenderTargetView;
}

d3d11_init :: () {
	hr: HRESULT = ---;

	desc: DXGI_SWAP_CHAIN_DESC;
	desc.BufferDesc.Format = .R16G16B16A16_FLOAT;
	desc.SampleDesc.Count = 1;
	desc.BufferUsage = .RENDER_TARGET_OUTPUT;
	desc.BufferCount = 2;
	desc.OutputWindow = platform_hwnd;
	desc.Windowed = xx true;
	desc.SwapEffect = .FLIP_DISCARD;
	desc.Flags = xx DXGI_SWAP_CHAIN_FLAG.ALLOW_MODE_SWITCH;
	hr = D3D11CreateDeviceAndSwapChain(null, .HARDWARE, null, xx ifx DEBUG D3D11_CREATE_DEVICE_FLAG.DEBUG, null, 0,
		D3D11_SDK_VERSION, *desc, *d3d11.swapchain, *d3d11.device, null, *d3d11.ctx);
	if FAILED(hr) { d3d11_deinit(); return; }
}

d3d11_deinit :: () {
	if d3d11.swapchain IUnknown_Release(d3d11.swapchain);
	if d3d11.device IUnknown_Release(d3d11.device);
	if d3d11.ctx IUnknown_Release(d3d11.ctx);
	if d3d11.backbuffer_view IUnknown_Release(d3d11.backbuffer_view);
	d3d11 = .{};
}

d3d11_resize :: () {
	if !d3d11.swapchain return;

	hr: HRESULT = ---;

	backbuffer: *ID3D11Texture2D;
	hr = IDXGISwapChain_GetBuffer(d3d11.swapchain, 0, *uid(ID3D11Texture2D_UUID), xx *backbuffer);
	if FAILED(hr) { d3d11_deinit(); return; }
	hr = ID3D11Device_CreateRenderTargetView(d3d11.device, backbuffer, null, *d3d11.backbuffer_view);
	if FAILED(hr) { d3d11_deinit(); return; }
	IUnknown_Release(backbuffer);
}

d3d11_present :: () {
	if !d3d11.swapchain return;

	ID3D11DeviceContext_ClearRenderTargetView(d3d11.ctx, d3d11.backbuffer_view, *(float32.[0.6, 0.2, 0.2, 1.0]));

	IDXGISwapChain_Present(d3d11.swapchain, 1, 0);
}
