Game_Renderer :: struct {
	Procs :: struct {
		clear_color: (color: [4]float32, index: u32 = 0);
		clear_depth: (depth: float32);
	}

	using procs: Procs;
}

game_update_and_render :: (renderer: *Game_Renderer) {

}
