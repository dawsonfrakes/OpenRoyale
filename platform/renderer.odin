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
	procs: game.Renderer_Procs,
}

nil_renderer := Renderer{
	init = proc() {},
	deinit = proc() {},
	resize = proc() {},
	present = proc() {},
	procs = {
		clear_color = proc(color: [4]f32, index: u32 = 0) {},
		rect = proc(position: [2]f32, size: [2]f32, color: [4]f32, texcoords: [2][2]f32, texture: game.Rect_Texture, rotation: f32, z_index: i32) {},
	},
}

platform_renderer: ^Renderer

renderer_switch_api :: proc(new_api: Render_API) {
	was_set_previously := platform_renderer != nil
	if was_set_previously do platform_renderer.deinit()
	switch new_api {
		case .NONE:
			platform_renderer = &nil_renderer
		case .D3D11:
			platform_renderer = &d3d11_renderer when ODIN_OS == .Windows else &nil_renderer
	}
	platform_renderer.init()
	if was_set_previously do platform_renderer.resize()
}
