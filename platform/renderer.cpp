#define RENDER_API_NONE 0
#define RENDER_API_D3D12 1

#define RENDER_API RENDER_API_D3D12

#if RENDER_API == RENDER_API_D3D12
#include "renderer_d3d12.cpp"
#define RENDER_API_NAME d3d12
#endif

#define renderer_cat2(A, B) A ## B
#define renderer_cat(A, B) renderer_cat2(A, B)
#define renderer_init renderer_cat(RENDER_API_NAME, _init)
#define renderer_deinit renderer_cat(RENDER_API_NAME, _deinit)
#define renderer_resize renderer_cat(RENDER_API_NAME, _resize)
#define renderer_present renderer_cat(RENDER_API_NAME, _present)
