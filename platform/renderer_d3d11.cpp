#include <D3D11.h>
#include <dxgi.h>
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
	{
		HRESULT hr;
		DXGI_SWAP_CHAIN_DESC sd = {};
		sd.BufferDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
		sd.SampleDesc.Count = 1;
		sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		sd.BufferCount = 2;
		sd.OutputWindow = platform_hwnd;
		sd.Windowed = true;
		sd.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
		hr = D3D11CreateDeviceAndSwapChain(null, D3D_DRIVER_TYPE_HARDWARE, null, DEBUG ? D3D11_CREATE_DEVICE_DEBUG : 0, null, 0, D3D11_SDK_VERSION,
			&sd, &d3d11.swapchain, &d3d11.device, null, &d3d11.context);
		if (FAILED(hr)) goto error;
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

void d3d11_present() {
	if (!d3d11.context) return;

	f32 color[] = {0.6f, 0.2f, 0.2f, 1.0f};
	d3d11.context->ClearRenderTargetView(d3d11.render_target_view, color);

	struct Vertex {
		f32 position[3];
		f32 color[3];
	};
	static Vertex vertices[] = {
		{{-0.5f, -0.5f, 0.0f}, {1.0f, 0.0f, 0.0f}},
		{{-0.5f, +0.5f, 0.0f}, {0.0f, 1.0f, 0.0f}},
		{{+0.5f, +0.5f, 0.0f}, {0.0f, 0.0f, 1.0f}},
		{{+0.5f, -0.5f, 0.0f}, {1.0f, 0.0f, 1.0f}},
	};
	static u16 indices[] = {
		0, 1, 2, 2, 3, 0,
	};

	D3D11_BUFFER_DESC bd = {};
	bd.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	bd.ByteWidth = size_of(vertices);
	D3D11_SUBRESOURCE_DATA sr = {};
	sr.pSysMem = vertices;
	ID3D11Buffer* vertex_buffer = null;
	d3d11.device->CreateBuffer(&bd, &sr, &vertex_buffer);

	bd.BindFlags = D3D11_BIND_INDEX_BUFFER;
	bd.ByteWidth = size_of(indices);
	sr.pSysMem = indices;
	ID3D11Buffer* index_buffer = null;
	d3d11.device->CreateBuffer(&bd, &sr, &index_buffer);

	ID3DBlob* shader_blob = null;
	char vsrc[] =
	"struct VSOut {\n"
		" float3 color : Color;\n"
		"	float4 pos : SV_Position;\n"
		"};\n"
		"VSOut main(float3 pos : Position, float3 color : Color) {\n"
		"  VSOut vso;\n"
		"  vso.pos = float4(pos, 1.0);\n"
		"  vso.color = color;\n"
		"  return vso;\n"
		"}\n";
	D3DCompile(vsrc, sizeof(vsrc) - 1, null, null, null, "main", "vs_5_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &shader_blob, null);
	ID3D11VertexShader* vertex_shader = null;
	d3d11.device->CreateVertexShader(shader_blob->GetBufferPointer(), shader_blob->GetBufferSize(), null, &vertex_shader);

	D3D11_INPUT_ELEMENT_DESC ild[] = {
		{"Position", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, offset_of(Vertex, position), D3D11_INPUT_PER_VERTEX_DATA, 0},
		{"Color", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, offset_of(Vertex, color), D3D11_INPUT_PER_VERTEX_DATA, 0},
	};
	ID3D11InputLayout* il = null;
	d3d11.device->CreateInputLayout(ild, size_of(ild) / size_of(ild[0]), shader_blob->GetBufferPointer(), shader_blob->GetBufferSize(), &il);

	char psrc[] =
		"float4 main(float3 color : Color) : SV_Target {\n"
		"  return float4(color, 1.0);\n"
		"}\n";
	D3DCompile(psrc, sizeof(psrc) - 1, null, null, null, "main", "ps_5_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &shader_blob, null);
	ID3D11PixelShader* pixel_shader = null;
	d3d11.device->CreatePixelShader(shader_blob->GetBufferPointer(), shader_blob->GetBufferSize(), null, &pixel_shader);
	shader_blob->Release();

	u32 vertex_stride = size_of(Vertex);
	u32 vertex_offset = 0;
	d3d11.context->IASetVertexBuffers(0, 1, &vertex_buffer, &vertex_stride, &vertex_offset);
	d3d11.context->IASetIndexBuffer(index_buffer, DXGI_FORMAT_R16_UINT, 0);

	d3d11.context->IASetInputLayout(il);

	d3d11.context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	d3d11.context->VSSetShader(vertex_shader, null, 0);
	d3d11.context->PSSetShader(pixel_shader, null, 0);

	d3d11.context->OMSetRenderTargets(1, &d3d11.render_target_view, null);

	D3D11_VIEWPORT viewport = {};
	viewport.Width = platform_width;
	viewport.Height = platform_height;
	viewport.MaxDepth = 1.0f;
	d3d11.context->RSSetViewports(1, &viewport);

	d3d11.context->DrawIndexed(size_of(indices) / size_of(indices[0]), 0, 0);

	d3d11.swapchain->Present(1, 0);

	il->Release();
	pixel_shader->Release();
	vertex_shader->Release();
	vertex_buffer->Release();
	index_buffer->Release();
}
