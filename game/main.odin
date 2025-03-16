package game

Renderer_Procs :: struct {
	clear_color: proc(color: [4]f32, index: u32 = 0),
}

Renderer :: struct {
	using procs: Renderer_Procs,
}

Input :: struct {
	delta: f32,
}

update_and_render :: proc(renderer: ^Renderer, input: ^Input) {
	renderer.clear_color({0.6, 0.2, 0.2, 1.0})
}
