package platform

import "../game"

when ODIN_OS == .Windows {
	RENDER_API :: #config(RENDER_API, "D3D11")
} else {
	RENDER_API :: #config(RENDER_API, "NONE")
}

Renderer :: struct {
	init: proc(),
	deinit: proc(),
	resize: proc(),
	present: proc(),
	procs: game.Renderer_Procs,
}

when RENDER_API == "D3D11" {
	renderer := Renderer{
		init = d3d11_init,
		deinit = d3d11_deinit,
		resize = d3d11_resize,
		present = d3d11_present,
		procs = {
			clear_color = d3d11_clear_color,
			clear_depth = d3d11_clear_depth,
		},
	}
} else {
	renderer :: Renderer{
		init = proc() {},
		deinit = proc() {},
		resize = proc() {},
		present = proc() {},
		procs = {
			clear_color = proc(color: [4]f32, index: u32) {},
			clear_depth = proc(depth: f32) {},
		},
	}
	#assert(RENDER_API == "NONE")
}
