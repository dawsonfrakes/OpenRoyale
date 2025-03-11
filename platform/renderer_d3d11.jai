d3d11_renderer :: struct {
	init :: d3d11_init;
	deinit :: d3d11_deinit;
	resize :: d3d11_resize;
	present :: d3d11_present;
	using procs :: Game_Renderer.Procs.{
		clear_color = d3d11_clear_color,
		clear_depth = d3d11_clear_depth,
	};
}

#scope_file

#import "d3d11";
#import "dxgi";

d3d11: struct {
	device: *ID3D11Device;
	swapchain: *IDXGISwapChain;
	ctx: *ID3D11DeviceContext;
}

check :: (hr: HRESULT, loc := #caller_location) #expand {
	if FAILED(hr) {
		print("[d3d11] error(hr=%\n) @ %", hr, loc);
		`return;
	}
}

d3d11_init :: () {
	desc: DXGI_SWAP_CHAIN_DESC;
	desc.BufferDesc.Format = .R16G16B16A16_FLOAT;
	desc.SampleDesc.Count = 1;
	desc.BufferUsage = .RENDER_TARGET_OUTPUT;
	desc.BufferCount = 2;
	desc.OutputWindow = platform_hwnd;
	desc.Windowed = xx true;
	desc.SwapEffect = .FLIP_DISCARD;
	desc.Flags = xx DXGI_SWAP_CHAIN_FLAG.ALLOW_MODE_SWITCH;
	check(D3D11CreateDeviceAndSwapChain(null, .HARDWARE, null, xx ifx DEBUG then D3D11_CREATE_DEVICE_FLAG.DEBUG else 0, null, 0, D3D11_SDK_VERSION,
		*desc, *d3d11.swapchain, *d3d11.device, null, *d3d11.ctx));
}

d3d11_deinit :: () {
	if d3d11.device IUnknown_Release(d3d11.device);
	if d3d11.swapchain IUnknown_Release(d3d11.swapchain);
	if d3d11.ctx IUnknown_Release(d3d11.ctx);
	d3d11 = .{};
}

d3d11_resize :: () {

}

d3d11_present :: () {
	IDXGISwapChain_Present(d3d11.swapchain, 1, 0);
}

d3d11_clear_color :: (color: [4]float32, index: u32) {

}

d3d11_clear_depth :: (depth: float32) {

}
