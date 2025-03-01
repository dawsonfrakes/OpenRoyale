struct Game_Renderer {
	void (*clear_color)(f32 color[4], u32 index);
	void (*clear_depth)(f32 depth);
};

extern "C" void game_update_and_render(Game_Renderer* renderer);
