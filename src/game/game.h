typedef struct {
	f32 delta;
} Game_Input;

typedef struct {
	void (*clear_color)(f32 color[4], u32 index);
} Game_Renderer_Procs;

typedef struct {
	Game_Renderer_Procs procs;
} Game_Renderer;

void game_update_and_render(Game_Input* input, Game_Renderer* renderer);
