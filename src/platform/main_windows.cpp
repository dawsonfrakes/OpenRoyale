#define null nullptr
#define cast(T) (T)
#define size_of(T) (cast(s64) sizeof(T))

typedef int s32;
typedef long long s64;

typedef unsigned short u16;
typedef unsigned int u32;

#define WIN32_LEAN_AND_MEAN
#define UNICODE
#define NOMINMAX
#include <Windows.h>
#include <Winsock2.h>
#include <Dwmapi.h>
#include <mmsystem.h>

HINSTANCE platform_hinstance;
HWND platform_hwnd;
HDC platform_hdc;
u16 platform_width;
u16 platform_height;

#if 1
#include "renderer_d3d11.cpp"
#define renderer_init d3d11_init
#define renderer_deinit d3d11_deinit
#define renderer_resize d3d11_resize
#define renderer_present d3d11_present
#endif

void update_cursor_clip(void) {
	ClipCursor(null);
}

void clear_held_keys(void) {

}

void toggle_fullscreen(void) {
	static WINDOWPLACEMENT save_placement = {size_of(WINDOWPLACEMENT)};

	u32 style = cast(u32) GetWindowLongPtrW(platform_hwnd, GWL_STYLE);
	if (style & WS_OVERLAPPEDWINDOW) {
		MONITORINFO mi = {size_of(MONITORINFO)};
		GetMonitorInfoW(MonitorFromWindow(platform_hwnd, MONITOR_DEFAULTTOPRIMARY), &mi);

		GetWindowPlacement(platform_hwnd, &save_placement);
		SetWindowLongPtrW(platform_hwnd, GWL_STYLE, style & ~cast(u32) WS_OVERLAPPEDWINDOW);
		SetWindowPos(platform_hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
			mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
			SWP_FRAMECHANGED);
	} else {
		SetWindowLongPtrW(platform_hwnd, GWL_STYLE, style | WS_OVERLAPPEDWINDOW);
		SetWindowPlacement(platform_hwnd, &save_placement);
		SetWindowPos(platform_hwnd, null, 0, 0, 0, 0, SWP_NOMOVE |
			SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
	}
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

			renderer_resize();
			return 0;
		case WM_CREATE: {
			platform_hwnd = hwnd;
			platform_hdc = GetDC(hwnd);

			s32 dark_mode = true;
			DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark_mode, size_of(dark_mode));
			s32 round_mode = DWMWCP_DONOTROUND;
			DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &round_mode, size_of(round_mode));

			renderer_init();
			return 0;
		}
		case WM_DESTROY:
			renderer_deinit();

			PostQuitMessage(0);
			return 0;
		case WM_SYSCOMMAND:
			if (wParam == SC_KEYMENU) return 0;
			// fallthrough
		default:
			return DefWindowProcW(hwnd, message, wParam, lParam);
	}
}

extern "C" [[noreturn]] void WINAPI WinMainCRTStartup(void) {
	platform_hinstance = GetModuleHandleW(null);

	WSADATA wsadata;
	bool networking_supported = WSAStartup(0x202, &wsadata) == 0;

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
	CreateWindowExW(0, wndclass.lpszClassName, L"Open Royale",
		WS_OVERLAPPEDWINDOW | WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		null, null, platform_hinstance, null);

	for (;;) {
		MSG msg;
		while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE)) {
			TranslateMessage(&msg);
			switch (msg.message) {
				case WM_KEYDOWN: // fallthrough
				case WM_KEYUP: // fallthrough
				case WM_SYSKEYDOWN: // fallthrough
				case WM_SYSKEYUP: {
					bool pressed = (msg.lParam & (1 << 31)) == 0;
					bool repeat = pressed && (msg.lParam & (1 << 30)) != 0;
					bool sys = msg.message == WM_SYSKEYDOWN || msg.message == WM_SYSKEYUP;
					bool alt = sys && (msg.lParam & (1 << 29)) != 0;

					if (!repeat && (!sys || alt || msg.wParam == VK_MENU || msg.wParam == VK_F10)) {
						if (pressed) {
							if (msg.wParam == VK_F4 && alt) DestroyWindow(platform_hwnd);
							if (DEBUG && msg.wParam == VK_ESCAPE) DestroyWindow(platform_hwnd);
							if (msg.wParam == VK_RETURN && alt) toggle_fullscreen();
							if (msg.wParam == VK_F11) toggle_fullscreen();
						}
					}
					break;
				}
				case WM_QUIT:
					goto main_loop_end;
				default:
					DispatchMessageW(&msg);
			}
		}

		renderer_present();

		if (sleep_is_granular) {
			Sleep(1);
		}
	}
main_loop_end:

	if (networking_supported) WSACleanup();

	ExitProcess(0);
}
