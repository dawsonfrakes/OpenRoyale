package game

Renderer_Procs :: struct {
	clear_color: proc(color: [4]f32, index := u32(0)),
	clear_depth: proc(depth: f32),
}

Renderer :: struct {
	using procs: Renderer_Procs,
}

Input :: struct {
	delta: f32,
}

update_and_render :: proc(input: ^Input, renderer: ^Renderer) {
	renderer.clear_color({0.6, 0.2, 0.2, 1.0})
	renderer.clear_depth(0.0)
}
