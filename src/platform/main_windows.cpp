#include "../basic.hpp"

#define WIN32_LEAN_AND_MEAN
#define UNICODE
#define NOMINMAX
#include <Windows.h>
#include <Winsock2.h>
#include <Dwmapi.h>
#include <mmsystem.h>
#include <D3D11.h>
#include <d3dcompiler.h>

HINSTANCE platform_hinstance;
HWND platform_hwnd;
HDC platform_hdc;
u16 platform_width;
u16 platform_height;

void update_cursor_clip(void) {
	ClipCursor(null);
}

void clear_held_keys(void) {

}

void toggle_fullscreen(void) {
	static WINDOWPLACEMENT save_placement = {size_of(WINDOWPLACEMENT)};
}

LRESULT WINAPI window_proc(HWND hwnd, u32 message, WPARAM wParam, LPARAM lParam) {
	switch (message) {
		case WM_PAINT:
			ValidateRect(hwnd, null);
			return 0;
		case WM_ERASEBKGND:
			return 1;
		case WM_ACTIVATEAPP: {
			bool tabbing_in = wParam != 0;

			if (tabbing_in) update_cursor_clip();
			else clear_held_keys();
			return 0;
		}
		case WM_SIZE:
			platform_width = cast(u16) lParam;
			platform_height = cast(u16) (lParam >> 16);
			return 0;
		case WM_CREATE: {
			platform_hwnd = hwnd;
			platform_hdc = GetDC(hwnd);

			s32 dark_mode = true;
			DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark_mode, size_of(s32));
			s32 round_mode = DWMWCP_DONOTROUND;
			DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &round_mode, size_of(s32));
			return 0;
		}
		case WM_DESTROY:
			PostQuitMessage(0);
			return 0;
		case WM_SYSCOMMAND:
			if (wParam == SC_KEYMENU) return 0;
			through;
		default:
			return DefWindowProcW(hwnd, message, wParam, lParam);
	}
}

extern "C" [[noreturn]] void WINAPI WinMainCRTStartup(void) {
	platform_hinstance = GetModuleHandleW(null);

	bool sleep_is_granular = timeBeginPeriod(1) == TIMERR_NOERROR;

	SetProcessDPIAware();
	WNDCLASSEXW wndclass = {};
	wndclass.cbSize = size_of(WNDCLASSEXW);
	wndclass.style = CS_OWNDC;
	wndclass.lpfnWndProc = window_proc;
	wndclass.hInstance = platform_hinstance;
	wndclass.hIcon = LoadIconW(null, IDI_WARNING);
	wndclass.hCursor = LoadCursorW(null, IDC_CROSS);
	wndclass.lpszClassName = L"A";
	RegisterClassExW(&wndclass);
	CreateWindowExW(0, wndclass.lpszClassName, L"Red Wheelbarrow",
		WS_OVERLAPPEDWINDOW | WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		null, null, platform_hinstance, null);

	for (;;) {
		MSG msg;
		while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE)) {
			TranslateMessage(&msg);
			switch (msg.message) {
				case WM_KEYDOWN: through;
				case WM_KEYUP: through;
				case WM_SYSKEYDOWN: through;
				case WM_SYSKEYUP: {
					break;
				}
				case WM_QUIT:
					goto main_loop_end;
				default:
					DispatchMessageW(&msg);
			}
		}

		if (sleep_is_granular) {
			Sleep(1);
		}
	}
main_loop_end:

	ExitProcess(0);
}

extern "C" s32 _fltused = 0;
