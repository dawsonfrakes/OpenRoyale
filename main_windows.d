#!dmd -betterC -debug -i

import platform_globals;
import basic.windows;

extern(Windows) noreturn WinMainCRTStartup() {
	platform_hinstance = GetModuleHandleW(null);

	SetProcessDPIAware();
	WNDCLASSEXW wndclass;
	wndclass.cbSize = WNDCLASSEXW.sizeof;
	wndclass.style = CS_OWNDC;
	wndclass.lpfnWndProc = (hwnd, message, wParam, lParam) {
		switch (message) {
			case WM_DESTROY:
				PostQuitMessage(0);
				return 0;
			default:
				return DefWindowProcW(hwnd, message, wParam, lParam);
		}
	};
	wndclass.hInstance = platform_hinstance;
	wndclass.hIcon = LoadIconW(null, IDI_WARNING);
	wndclass.hCursor = LoadCursorW(null, IDC_CROSS);
	wndclass.lpszClassName = "A";
	RegisterClassExW(&wndclass);
	CreateWindowExW(0, wndclass.lpszClassName, "Open Royale",
		WS_OVERLAPPEDWINDOW | WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		null, null, platform_hinstance, null);

	ExitProcess(0);
}

pragma(lib, "kernel32");
pragma(lib, "user32");
pragma(lib, "ws2_32");
pragma(lib, "dwmapi");
pragma(lib, "winmm");
pragma(lib, "d3d11");
debug {
	pragma(linkerDirective, "-subsystem:console");
	pragma(linkerDirective, "-entry:WinMainCRTStartup");
} else {
	pragma(linkerDirective, "-subsystem:windows");
}
