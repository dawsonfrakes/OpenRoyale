package platform

import "../game"

Render_API :: enum {
	NONE = 0,
	D3D11 = 1,
}

Renderer :: struct {
	init: proc(),
	deinit: proc(),
	resize: proc(),
	present: proc(),
	using procs: game.Renderer_Procs,
}

platform_renderer: ^Renderer

nil_renderer := Renderer{
	init = proc() {},
	deinit = proc() {},
	resize = proc() {},
	present = proc() {},
	procs = {
		clear_color = proc(color: [4]f32, index: u32) {},
	},
}

renderer_switch_api :: proc(new_api: Render_API) {
	was_set_before := platform_renderer != nil
	if was_set_before do platform_renderer.deinit()
	switch new_api {
		case .NONE:
			platform_renderer = &nil_renderer
		case .D3D11:
			assert(ODIN_OS == .Windows)
			platform_renderer = &d3d11_renderer when ODIN_OS == .Windows else &nil_renderer
	}
	platform_renderer.init()
	if was_set_before do platform_renderer.resize()
}
