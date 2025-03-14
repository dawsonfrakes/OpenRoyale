module basic.windows;

import basic : foreign;

// kernel32
struct HINSTANCE__;
alias HINSTANCE = HINSTANCE__*;
alias HMODULE = HINSTANCE;
alias PROC = extern(Windows) ptrdiff_t function();

@foreign("kernel32") extern(Windows) HMODULE GetModuleHandleW(const(wchar)*);
@foreign("kernel32") extern(Windows) HMODULE LoadLibraryW(const(wchar)*);
@foreign("kernel32") extern(Windows) PROC GetProcAddress(HMODULE, const(char)*);
@foreign("kernel32") extern(Windows) void Sleep(uint);
@foreign("kernel32") extern(Windows) noreturn ExitProcess(uint);

// user32
enum IDI_WARNING = cast(const(wchar)*) 32515;
enum IDC_CROSS = cast(const(wchar)*) 32515;
enum CS_OWNDC = 0x0020;
enum WS_MAXIMIZEBOX = 0x00010000;
enum WS_MINIMIZEBOX = 0x00020000;
enum WS_THICKFRAME = 0x00040000;
enum WS_SYSMENU = 0x00080000;
enum WS_CAPTION = 0x00C00000;
enum WS_VISIBLE = 0x10000000;
enum WS_OVERLAPPEDWINDOW = WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
enum CW_USEDEFAULT = 0x80000000;
enum WM_DESTROY = 0x0002;

struct HDC__;
alias HDC = HDC__*;
struct HWND__;
alias HWND = HWND__*;
struct HMENU__;
alias HMENU = HMENU__*;
struct HICON__;
alias HICON = HICON__*;
struct HBRUSH__;
alias HBRUSH = HBRUSH__*;
struct HCURSOR__;
alias HCURSOR = HCURSOR__*;
struct HMONITOR__;
alias HMONITOR = HMONITOR__*;
alias WNDPROC = extern(Windows) ptrdiff_t function(HWND, uint, size_t, ptrdiff_t);
struct WNDCLASSEXW {
	uint cbSize;
	uint style;
	WNDPROC lpfnWndProc;
	int cbClsExtra;
	int cbWndExtra;
	HINSTANCE hInstance;
	HICON hIcon;
	HCURSOR hCursor;
	HBRUSH hbrBackground;
	const(wchar)* lpszMenuName;
	const(wchar)* lpszClassName;
	HICON hIconSm;
}

@foreign("user32") extern(Windows) int SetProcessDPIAware();
@foreign("user32") extern(Windows) HICON LoadIconW(HINSTANCE, const(wchar)*);
@foreign("user32") extern(Windows) HCURSOR LoadCursorW(HINSTANCE, const(wchar)*);
@foreign("user32") extern(Windows) ushort RegisterClassExW(const(WNDCLASSEXW)*);
@foreign("user32") extern(Windows) HWND CreateWindowExW(uint, const(wchar)*, const(wchar)*, uint, int, int, int, int, HWND, HMENU, HINSTANCE, void*);
@foreign("user32") extern(Windows) void PostQuitMessage(int);
@foreign("user32") extern(Windows) ptrdiff_t DefWindowProcW(HWND, uint, size_t, ptrdiff_t);
