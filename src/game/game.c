#include "../basic.h"
#include "game.h"

void game_update_and_render(Game_Input* input, Game_Renderer* renderer) {
	cast(void) input;
	renderer->procs.clear_color((f32[4]) {0.6f, 0.2f, 0.2f, 1.0f}, 0);
}
