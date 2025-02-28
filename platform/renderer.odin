package platform

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
}

when RENDER_API == "D3D11" {
	renderer := Renderer{
		init = d3d11_init,
		deinit = d3d11_deinit,
		resize = d3d11_resize,
		present = d3d11_present,
	}
} else {
	renderer :: Renderer{
		init = proc() {},
		deinit = proc() {},
		resize = proc() {},
		present = proc() {},
	}
	#assert(RENDER_API == "NONE")
}
