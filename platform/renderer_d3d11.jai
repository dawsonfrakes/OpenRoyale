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

Rect_Vertex :: struct {
	position: [2]float32;
}
Rect_Instance :: struct {
	offset: [2]float32;
	color: [4]float32;
}
rect_indices :: u16.[0, 1, 2, 2, 3, 0];
rect_vertices :: Rect_Vertex.[
	.{.[-0.5, -0.5]},
	.{.[-0.5, +0.5]},
	.{.[+0.5, +0.5]},
	.{.[+0.5, -0.5]},
];
rect_instances :: Rect_Instance.[
	.{.[+0.5, +0.5], .[1.0, 1.0, 0.0, 1.0]},
	.{.[-0.5, -0.5], .[1.0, 0.0, 1.0, 1.0]},
];

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
	rect_vertex_shader: *ID3D11VertexShader;
	rect_pixel_shader: *ID3D11PixelShader;
	rect_input_layout: *ID3D11InputLayout;
	rect_vertex_buffer: *ID3D11Buffer;
	rect_index_buffer: *ID3D11Buffer;
	rect_instance_buffer: *ID3D11Buffer;
	backbuffer_view: *ID3D11RenderTargetView;
	depthbuffer_view: *ID3D11DepthStencilView;
	depth_stencil_state: *ID3D11DepthStencilState;
}

d3d11_init :: () {
	desc: DXGI_SWAP_CHAIN_DESC;
	desc.BufferDesc.Format = .R16G16B16A16_FLOAT;
	desc.SampleDesc.Count = 4;
	desc.BufferUsage = .RENDER_TARGET_OUTPUT;
	desc.BufferCount = 3;
	desc.OutputWindow = platform_hwnd;
	desc.Windowed = xx true;
	desc.SwapEffect = .DISCARD;
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

	{
		src :: #string DONE
struct VSIn {
	float2 position : POSITION;
	float2 offset : OFFSET;
	float4 color : COLOR;
};
struct VSOut {
	float4 color : COLOR;
	float4 position : SV_Position;
};
VSOut main(VSIn input) {
	VSOut output;
	output.position = float4(input.position + input.offset, 0.0, 1.0);
	output.color = input.color;
	return output;
}
DONE;
		blob: *ID3DBlob;
		check(D3DCompile(src.data, cast(u64) src.count, null, null, null, "main", "vs_5_0", xx D3DCOMPILE.ENABLE_STRICTNESS, 0, *blob, null));
		defer IUnknown_Release(blob);
		check(ID3D11Device_CreateVertexShader(d3d11.device, ID3D10Blob_GetBufferPointer(blob), ID3D10Blob_GetBufferSize(blob), null, *d3d11.rect_vertex_shader));

		descs :: D3D11_INPUT_ELEMENT_DESC.[
			.{"POSITION", 0, .R32G32_FLOAT, 0, 0, xx .VERTEX_DATA, 0},
			.{"OFFSET", 0, .R32G32_FLOAT, 1, 0, xx .INSTANCE_DATA, 1},
			.{"COLOR", 0, .R32G32B32A32_FLOAT, 1, 2 * size_of(float32), xx .INSTANCE_DATA, 1},
		];
		check(ID3D11Device_CreateInputLayout(d3d11.device, descs.data, descs.count, ID3D10Blob_GetBufferPointer(blob), ID3D10Blob_GetBufferSize(blob), *d3d11.rect_input_layout));
	}

	{
		src :: #string DONE
float4 main(float4 color : COLOR) : SV_Target {
	return color;
}
DONE;
		blob: *ID3DBlob;
		check(D3DCompile(src.data, cast(u64) src.count, null, null, null, "main", "ps_5_0", xx D3DCOMPILE.ENABLE_STRICTNESS, 0, *blob, null));
		defer IUnknown_Release(blob);
		check(ID3D11Device_CreatePixelShader(d3d11.device, ID3D10Blob_GetBufferPointer(blob), ID3D10Blob_GetBufferSize(blob), null, *d3d11.rect_pixel_shader));
	}

	{
		desc: D3D11_BUFFER_DESC;
		desc.ByteWidth = rect_vertices.count * size_of(Rect_Vertex);
		desc.Usage = .DEFAULT;
		desc.BindFlags = .VERTEX_BUFFER;
		desc.StructureByteStride = size_of(Rect_Vertex);
		sr: D3D11_SUBRESOURCE_DATA;
		sr.pSysMem = rect_vertices.data;
		check(ID3D11Device_CreateBuffer(d3d11.device, *desc, *sr, *d3d11.rect_vertex_buffer));
	}

	{
		desc: D3D11_BUFFER_DESC;
		desc.ByteWidth = rect_instances.count * size_of(Rect_Instance);
		desc.Usage = .DEFAULT;
		desc.BindFlags = .VERTEX_BUFFER;
		desc.StructureByteStride = size_of(Rect_Vertex);
		sr: D3D11_SUBRESOURCE_DATA;
		sr.pSysMem = rect_instances.data;
		check(ID3D11Device_CreateBuffer(d3d11.device, *desc, *sr, *d3d11.rect_instance_buffer));
	}

	{
		desc: D3D11_BUFFER_DESC;
		desc.ByteWidth = rect_indices.count * size_of(u16);
		desc.Usage = .DEFAULT;
		desc.BindFlags = .INDEX_BUFFER;
		desc.StructureByteStride = size_of(u16);
		sr: D3D11_SUBRESOURCE_DATA;
		sr.pSysMem = rect_indices.data;
		check(ID3D11Device_CreateBuffer(d3d11.device, *desc, *sr, *d3d11.rect_index_buffer));
	}
}

d3d11_deinit :: () {
	if d3d11.swapchain IUnknown_Release(d3d11.swapchain);
	if d3d11.device IUnknown_Release(d3d11.device);
	if d3d11.ctx IUnknown_Release(d3d11.ctx);
	if d3d11.rect_vertex_shader IUnknown_Release(d3d11.rect_vertex_shader);
	if d3d11.rect_pixel_shader IUnknown_Release(d3d11.rect_pixel_shader);
	if d3d11.rect_input_layout IUnknown_Release(d3d11.rect_input_layout);
	if d3d11.rect_vertex_buffer IUnknown_Release(d3d11.rect_vertex_buffer);
	if d3d11.rect_index_buffer IUnknown_Release(d3d11.rect_index_buffer);
	if d3d11.rect_instance_buffer IUnknown_Release(d3d11.rect_instance_buffer);
	if d3d11.backbuffer_view IUnknown_Release(d3d11.backbuffer_view);
	if d3d11.depthbuffer_view IUnknown_Release(d3d11.depthbuffer_view);
	if d3d11.depth_stencil_state IUnknown_Release(d3d11.depth_stencil_state);
	d3d11 = .{};
}

d3d11_resize :: () {
	if !d3d11.swapchain return;

	ID3D11DeviceContext_OMSetRenderTargets(d3d11.ctx, 0, null, null);

	if d3d11.backbuffer_view IUnknown_Release(d3d11.backbuffer_view);
	d3d11.backbuffer_view = null;
	if d3d11.depthbuffer_view IUnknown_Release(d3d11.depthbuffer_view);
	d3d11.depthbuffer_view = null;
	if d3d11.depth_stencil_state IUnknown_Release(d3d11.depth_stencil_state);
	d3d11.depth_stencil_state = null;

	check(IDXGISwapChain_ResizeBuffers(d3d11.swapchain, 0, 0, 0, 0, xx DXGI_SWAP_CHAIN_FLAG.ALLOW_MODE_SWITCH));

	backbuffer: *ID3D11Texture2D;
	check(IDXGISwapChain_GetBuffer(d3d11.swapchain, 0, *uid(ID3D11Texture2D_UUID), xx *backbuffer));
	check(ID3D11Device_CreateRenderTargetView(d3d11.device, backbuffer, null, *d3d11.backbuffer_view));
	IUnknown_Release(backbuffer);

	{
		desc: D3D11_TEXTURE2D_DESC;
		desc.Width = platform_width;
		desc.Height = platform_height;
		desc.MipLevels = 1;
		desc.ArraySize = 1;
		desc.Format = .D32_FLOAT;
		desc.SampleDesc.Count = 4;
		desc.Usage = .DEFAULT;
		desc.BindFlags = .DEPTH_STENCIL;
		depthbuffer: *ID3D11Texture2D;
		check(ID3D11Device_CreateTexture2D(d3d11.device, *desc, null, *depthbuffer));
		check(ID3D11Device_CreateDepthStencilView(d3d11.device, depthbuffer, null, *d3d11.depthbuffer_view));
		IUnknown_Release(depthbuffer);
	}

	{
		desc: D3D11_DEPTH_STENCIL_DESC;
		desc.DepthEnable = xx true;
		desc.DepthWriteMask = .ALL;
		desc.DepthFunc = .GREATER_EQUAL;
		check(ID3D11Device_CreateDepthStencilState(d3d11.device, *desc, *d3d11.depth_stencil_state));
	}
}

d3d11_present :: () {
	if !d3d11.swapchain return;

	ID3D11DeviceContext_OMSetRenderTargets(d3d11.ctx, 1, *d3d11.backbuffer_view, d3d11.depthbuffer_view);
	ID3D11DeviceContext_OMSetDepthStencilState(d3d11.ctx, d3d11.depth_stencil_state, 0);
	ID3D11DeviceContext_VSSetShader(d3d11.ctx, d3d11.rect_vertex_shader, null, 0);
	ID3D11DeviceContext_PSSetShader(d3d11.ctx, d3d11.rect_pixel_shader, null, 0);
	ID3D11DeviceContext_IASetPrimitiveTopology(d3d11.ctx, .TRIANGLELIST);
	ID3D11DeviceContext_IASetInputLayout(d3d11.ctx, d3d11.rect_input_layout);
	vertex_buffers := (*ID3D11Buffer).[d3d11.rect_vertex_buffer, d3d11.rect_instance_buffer];
	vertex_strides := u32.[size_of(Rect_Vertex), size_of(Rect_Instance)];
	vertex_offsets := u32.[0, 0];
	ID3D11DeviceContext_IASetVertexBuffers(d3d11.ctx, 0, vertex_buffers.count, vertex_buffers.data, vertex_strides.data, vertex_offsets.data);
	ID3D11DeviceContext_IASetIndexBuffer(d3d11.ctx, d3d11.rect_index_buffer, .R16_UINT, 0);
	viewport: D3D11_VIEWPORT;
	viewport.Width = cast(float32) platform_width;
	viewport.Height = cast(float32) platform_height;
	viewport.MaxDepth = 1.0;
	ID3D11DeviceContext_RSSetViewports(d3d11.ctx, 1, *viewport);

	ID3D11DeviceContext_DrawIndexedInstanced(d3d11.ctx, rect_indices.count, rect_instances.count, 0, 0, 0);

	check(IDXGISwapChain_Present(d3d11.swapchain, 1, 0));
}

d3d11_clear_color :: (color: [4]float32, index := 0) {
	assert(index == 0);
	ID3D11DeviceContext_ClearRenderTargetView(d3d11.ctx, d3d11.backbuffer_view, *color);
}

d3d11_clear_depth :: (depth: float32) {
	ID3D11DeviceContext_ClearDepthStencilView(d3d11.ctx, d3d11.depthbuffer_view, xx D3D11_CLEAR_FLAG.DEPTH, depth, 0);
}
