Game_Renderer :: struct {
	Procs :: struct {
		clear_color: (color: [4]float32, index := 0);
		clear_depth: (depth: float32);
	}

	using procs: Procs;
}

game_update_and_render :: (renderer: *Game_Renderer) {
	renderer.clear_color(.[0.6, 0.2, 0.2, 1.0]);
	renderer.clear_depth(0.0);
}
