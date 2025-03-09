typedef signed char s8;
typedef short s16;
typedef int s32;
typedef long long s64;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

typedef float f32;
typedef double f64;

#define WIN32_LEAN_AND_MEAN
#define UNICODE
#define NOMINMAX
#include <Windows.h>
#include <Winsock2.h>
#include <Dwmapi.h>
#include <mmsystem.h>
#include <D3D11.h>
#include <d3dcompiler.h>

extern "C" [[noreturn]] void WINAPI WinMainCRTStartup(void) {
	ExitProcess(0);
}

extern "C" s32 _fltused = 0;
