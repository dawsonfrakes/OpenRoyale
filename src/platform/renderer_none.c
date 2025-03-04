void none_init(void) {

}

void none_deinit(void) {

}

void none_resize(void) {

}

void none_present(void) {

}

void none_clear_color(f32 color[4], u32 index) {
	cast(void) color;
	cast(void) index;
}

Platform_Renderer renderer_none = {
	none_init,
	none_deinit,
	none_resize,
	none_present,
	{
		none_clear_color,
	},
};
