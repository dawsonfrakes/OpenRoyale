package game

Rect_Texture :: enum {
	WHITE = 0,
	FONT = 1,
}

Renderer_Procs :: struct {
	clear_color: proc(color: [4]f32, index: u32 = 0),
	rect: proc(position: [2]f32, size: [2]f32, color: [4]f32, texcoords: [2][2]f32, texture: Rect_Texture, rotation: f32, z_index: i32),
}

Renderer :: struct {
	using procs: Renderer_Procs,
}

Input :: struct {
	delta: f32,
}

update_and_render :: proc(renderer: ^Renderer, input: ^Input) {
	renderer.clear_color({0.6, 0.2, 0.2, 1.0})
	renderer.rect({100, 100}, {100, 100}, {1, 1, 1, 1}, {{0, 0}, {1, 1}}, .WHITE, 0, 0)
}
