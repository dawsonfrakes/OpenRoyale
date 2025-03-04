#define RENDER_API_NONE (1 << 0)
#define RENDER_API_D3D11 (1 << 1)

#define RENDER_APIS (RENDER_API_NONE | RENDER_API_D3D11)

typedef struct {
	void (*init)(void);
	void (*deinit)(void);
	void (*resize)(void);
	void (*present)(void);
	Game_Renderer_Procs procs;
} Platform_Renderer;

void renderer_switch_api(int new_api);

#if RENDER_APIS & RENDER_API_NONE
#include "renderer_none.c"
#endif
#if RENDER_APIS & RENDER_API_D3D11
#include "renderer_d3d11.c"
#endif

Platform_Renderer* platform_renderer;

void renderer_switch_api(int new_api) {
	bool was_set_before = platform_renderer != null;
	if (was_set_before) platform_renderer->deinit();
	switch (new_api) {
#if RENDER_APIS & RENDER_API_NONE
		case RENDER_API_NONE: platform_renderer = &renderer_none; break;
#endif
#if RENDER_APIS & RENDER_API_D3D11
		case RENDER_API_D3D11: platform_renderer = &renderer_d3d11; break;
#endif
		default: unreachable;
	}
	platform_renderer->init();
	if (was_set_before) platform_renderer->resize();
}
