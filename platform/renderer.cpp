#define RENDER_API_NONE 0
#define RENDER_API_SOFTWARE 1

#if RENDER_API == RENDER_API_SOFTWARE
#include "renderer_software.cpp"
#define RENDER_API_NAME swr
#elif RENDER_API == RENDER_API_NONE
void none_init() {}
void none_deinit() {}
void none_resize() {}
void none_fullscreen() {}
void none_present() {}
void none_clear_color(f32 color[4], u32 index) { (void) color; (void) index; }
void none_clear_depth(f32 depth) { (void) depth; }
#define RENDER_API_NAME none
#else
#error RENDER_API unsupported
#endif

#define renderer_concat2(A, B) A ## B
#define renderer_concat(A, B) renderer_concat2(A, B)
#define renderer_init renderer_concat(RENDER_API_NAME, _init)
#define renderer_deinit renderer_concat(RENDER_API_NAME, _deinit)
#define renderer_resize renderer_concat(RENDER_API_NAME, _resize)
#define renderer_fullscreen renderer_concat(RENDER_API_NAME, _fullscreen)
#define renderer_present renderer_concat(RENDER_API_NAME, _present)
#define renderer_clear_color renderer_concat(RENDER_API_NAME, _clear_color)
#define renderer_clear_depth renderer_concat(RENDER_API_NAME, _clear_depth)
