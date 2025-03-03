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
#import "d3d_compiler";

check :: (hr: HRESULT) #expand {
	if FAILED(hr) {
		d3d11_deinit();
		`return;
	}
}

d3d11: struct {
	swapchain: *IDXGISwapChain;
	device: *ID3D11Device;
	ctx: *ID3D11DeviceContext;

	using sized: struct {
		swapchain_backbuffer: *ID3D11Texture2D;
		backbuffer: *ID3D11Texture2D;
		backbuffer_view: *ID3D11RenderTargetView;
		depthbuffer_view: *ID3D11DepthStencilView;
	};
}

d3d11_init :: () {
	desc: DXGI_SWAP_CHAIN_DESC;
	desc.BufferDesc.Format = .R16G16B16A16_FLOAT;
	desc.SampleDesc.Count = 1;
	desc.BufferUsage = .RENDER_TARGET_OUTPUT;
	desc.BufferCount = 3;
	desc.OutputWindow = platform_hwnd;
	desc.Windowed = xx true;
	desc.SwapEffect = .FLIP_DISCARD;
	desc.Flags = xx DXGI_SWAP_CHAIN_FLAG.ALLOW_MODE_SWITCH;
	check(D3D11CreateDeviceAndSwapChain(null, .HARDWARE, null, xx ifx DEBUG D3D11_CREATE_DEVICE_FLAG.DEBUG, null, 0,
		D3D11_SDK_VERSION, *desc, *d3d11.swapchain, *d3d11.device, null, *d3d11.ctx));

	dxgi_device: *IDXGIDevice;
	dxgi_adapter: *IDXGIAdapter;
	dxgi_factory: *IDXGIFactory;
	if SUCCEEDED(IDXGIDeviceSubObject_GetDevice(d3d11.swapchain, *uid(IDXGIDevice_UUID), xx *dxgi_device)) {
		if SUCCEEDED(IDXGIDevice_GetAdapter(dxgi_device, *dxgi_adapter)) {
			if SUCCEEDED(IDXGIObject_GetParent(dxgi_adapter, *uid(IDXGIFactory_UUID), xx *dxgi_factory)) {
				IDXGIFactory_MakeWindowAssociation(dxgi_factory, platform_hwnd, xx DXGI_MWA.NO_ALT_ENTER);
				IUnknown_Release(dxgi_factory);
			}
			IUnknown_Release(dxgi_adapter);
		}
		IUnknown_Release(dxgi_device);
	}
}

d3d11_deinit_sized :: () {
	if d3d11.swapchain_backbuffer IUnknown_Release(d3d11.swapchain_backbuffer);
	if d3d11.backbuffer IUnknown_Release(d3d11.backbuffer);
	if d3d11.backbuffer_view IUnknown_Release(d3d11.backbuffer_view);
	if d3d11.depthbuffer_view IUnknown_Release(d3d11.depthbuffer_view);
	d3d11.sized = .{};
}

d3d11_deinit :: () {
	d3d11_deinit_sized();
	if d3d11.swapchain IUnknown_Release(d3d11.swapchain);
	if d3d11.device IUnknown_Release(d3d11.device);
	if d3d11.ctx IUnknown_Release(d3d11.ctx);
	d3d11 = .{};
}

d3d11_resize :: () {
	if !d3d11.swapchain return;

	ID3D11DeviceContext_OMSetRenderTargets(d3d11.ctx, 0, null, null);

	d3d11_deinit_sized();

	check(IDXGISwapChain_ResizeBuffers(d3d11.swapchain, 0, 0, 0, 0, xx DXGI_SWAP_CHAIN_FLAG.ALLOW_MODE_SWITCH));

	{
		desc: D3D11_TEXTURE2D_DESC;
		desc.Width = platform_width;
		desc.Height = platform_height;
		desc.MipLevels = 1;
		desc.ArraySize = 1;
		desc.Format = .R16G16B16A16_FLOAT;
		desc.SampleDesc.Count = 4;
		desc.Usage = .DEFAULT;
		desc.BindFlags = .RENDER_TARGET;
		check(ID3D11Device_CreateTexture2D(d3d11.device, *desc, null, *d3d11.backbuffer));
		check(ID3D11Device_CreateRenderTargetView(d3d11.device, d3d11.backbuffer, null, *d3d11.backbuffer_view));
	}

	{
		depthbuffer: *ID3D11Texture2D;
		desc: D3D11_TEXTURE2D_DESC;
		desc.Width = platform_width;
		desc.Height = platform_height;
		desc.MipLevels = 1;
		desc.ArraySize = 1;
		desc.Format = .D32_FLOAT;
		desc.SampleDesc.Count = 4;
		desc.Usage = .DEFAULT;
		desc.BindFlags = .DEPTH_STENCIL;
		check(ID3D11Device_CreateTexture2D(d3d11.device, *desc, null, *depthbuffer));
		defer IUnknown_Release(depthbuffer);

		check(ID3D11Device_CreateDepthStencilView(d3d11.device, depthbuffer, null, *d3d11.depthbuffer_view));
	}
}

d3d11_present :: () {
	if !d3d11.swapchain return;

	if d3d11.swapchain_backbuffer IUnknown_Release(d3d11.swapchain_backbuffer);
	check(IDXGISwapChain_GetBuffer(d3d11.swapchain, 0, *uid(ID3D11Texture2D_UUID), xx *d3d11.swapchain_backbuffer));

	ID3D11DeviceContext_ResolveSubresource(d3d11.ctx, d3d11.swapchain_backbuffer, 0, d3d11.backbuffer, 0, .R16G16B16A16_FLOAT);

	check(IDXGISwapChain_Present(d3d11.swapchain, 1, 0));
}

d3d11_clear_color :: (color: [4]float32, index: int) {
	if !d3d11.ctx return;
	assert(index == 0);
	ID3D11DeviceContext_ClearRenderTargetView(d3d11.ctx, d3d11.backbuffer_view, *color);
}

d3d11_clear_depth :: (depth: float32) {
	if !d3d11.ctx return;
	ID3D11DeviceContext_ClearDepthStencilView(d3d11.ctx, d3d11.depthbuffer_view, xx D3D11_CLEAR_FLAG.DEPTH, depth, 0);
}
