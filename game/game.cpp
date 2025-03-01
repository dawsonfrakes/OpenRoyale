#include "../basic.hpp"
#include "game.hpp"

extern "C" void game_update_and_render(Game_Renderer* renderer) {
	f32 color[4] = {0.6f, 0.2f, 0.2f, 1.0f};
	renderer->clear_color(color, 0);
}
