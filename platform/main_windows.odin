package platform

import w "core:sys/windows"
DWMWCP_DONOTROUND :: 1

platform_hinstance: w.HINSTANCE
platform_hwnd: w.HWND
platform_hdc: w.HDC
platform_size: [2]u16

main :: proc() {
	update_cursor_clip :: proc() {
		w.ClipCursor(nil)
	}

	clear_held_keys :: proc() {

	}

	toggle_fullscreen :: proc() {
		@static save_placement := w.WINDOWPLACEMENT{length = size_of(w.WINDOWPLACEMENT)}

		style := u32(w.GetWindowLongW(platform_hwnd, w.GWL_STYLE))
		if style & w.WS_OVERLAPPEDWINDOW != 0 {
			mi := w.MONITORINFO{cbSize = size_of(w.MONITORINFO)}
			w.GetMonitorInfoW(w.MonitorFromWindow(platform_hwnd, .MONITOR_DEFAULTTONEAREST), &mi)

			w.GetWindowPlacement(platform_hwnd, &save_placement)
			w.SetWindowLongW(platform_hwnd, w.GWL_STYLE, i32(style & ~u32(w.WS_OVERLAPPEDWINDOW)))
			w.SetWindowPos(platform_hwnd, w.HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
				mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
				w.SWP_FRAMECHANGED)
		} else {
			w.SetWindowLongW(platform_hwnd, w.GWL_STYLE, i32(style | w.WS_OVERLAPPEDWINDOW))
			w.SetWindowPlacement(platform_hwnd, &save_placement)
			w.SetWindowPos(platform_hwnd, nil, 0, 0, 0, 0, w.SWP_NOMOVE |
				w.SWP_NOSIZE | w.SWP_NOZORDER | w.SWP_FRAMECHANGED)
		}
	}

	platform_hinstance = w.HINSTANCE(w.GetModuleHandleW(nil))

	wsadata: w.WSADATA = ---
	networking_supported := w.WSAStartup(0x202, &wsadata) == 0
	defer if networking_supported do w.WSACleanup()

	sleep_is_granular := w.timeBeginPeriod(1) == w.TIMERR_NOERROR

	clock_frequency: w.LARGE_INTEGER = ---
	w.QueryPerformanceFrequency(&clock_frequency)
	clock_start: w.LARGE_INTEGER = ---
	w.QueryPerformanceCounter(&clock_start)
	clock_previous := clock_start

	w.SetProcessDPIAware()
	wndclass: w.WNDCLASSEXW
	wndclass.cbSize = size_of(w.WNDCLASSEXW)
	wndclass.style = w.CS_OWNDC
	wndclass.lpfnWndProc = proc "std" (hwnd: w.HWND, message: u32, wParam: uintptr, lParam: int) -> int {
		context = {}
		switch message {
			case w.WM_PAINT:
				w.ValidateRect(hwnd, nil)
			case w.WM_ERASEBKGND:
				return 1
			case w.WM_ACTIVATEAPP:
				tabbing_in := wParam != 0
				if tabbing_in do update_cursor_clip()
				else do clear_held_keys()
			case w.WM_SIZE:
				x := u16(lParam)
				y := u16(lParam >> 16)
				platform_size = {x, y}

				renderer.resize()
			case w.WM_CREATE:
				platform_hwnd = hwnd
				platform_hdc = w.GetDC(hwnd)

				dark_mode: b32 = true
				w.DwmSetWindowAttribute(hwnd, cast(u32) w.DWMWINDOWATTRIBUTE.DWMWA_USE_IMMERSIVE_DARK_MODE, &dark_mode, size_of(type_of(dark_mode)))
				round_mode: i32 = DWMWCP_DONOTROUND
				w.DwmSetWindowAttribute(hwnd, cast(u32) w.DWMWINDOWATTRIBUTE.DWMWA_USE_IMMERSIVE_DARK_MODE, &round_mode, size_of(type_of(round_mode)))

				renderer.init()
			case w.WM_DESTROY:
				renderer.deinit()

				w.PostQuitMessage(0)
			case w.WM_SYSCOMMAND:
				if wParam == w.SC_KEYMENU do return 0
				fallthrough
			case:
				return w.DefWindowProcW(hwnd, message, wParam, lParam)
		}
		return 0
	}
	wndclass.hInstance = platform_hinstance
	wndclass.hIcon = w.LoadIconW(nil, cast([^]u16) cast(rawptr) w.IDI_WARNING)
	wndclass.hCursor = w.LoadCursorW(nil, cast([^]u16) cast(rawptr) w.IDC_CROSS)
	wndclass.lpszClassName = raw_data([]u16{'A', 0})
	w.RegisterClassExW(&wndclass)
	w.CreateWindowExW(0, wndclass.lpszClassName, raw_data([]u16{'R', 'e', 'd', ' ', 'W', 'h', 'e', 'e', 'l', 'b', 'a', 'r', 'r', 'o', 'w', 0}),
		w.WS_OVERLAPPEDWINDOW | w.WS_VISIBLE,
		w.CW_USEDEFAULT, w.CW_USEDEFAULT, w.CW_USEDEFAULT, w.CW_USEDEFAULT,
		nil, nil, platform_hinstance, nil)

	main_loop: for {
		clock_frame_start: w.LARGE_INTEGER = ---
		w.QueryPerformanceCounter(&clock_frame_start)

		msg: w.MSG = ---
		for w.PeekMessageW(&msg, nil, 0, 0, w.PM_REMOVE) {
			w.TranslateMessage(&msg)
			switch msg.message {
				case w.WM_KEYDOWN: fallthrough
				case w.WM_KEYUP: fallthrough
				case w.WM_SYSKEYDOWN: fallthrough
				case w.WM_SYSKEYUP:
					pressed := msg.lParam & (1 << 31) == 0
					repeat := pressed && msg.lParam & (1 << 30) != 0
					sys := msg.message == w.WM_SYSKEYDOWN || msg.message == w.WM_SYSKEYUP
					alt := sys && msg.lParam & (1 << 29) != 0

					if !repeat && (!sys || alt || msg.wParam == w.VK_MENU || msg.wParam == w.VK_F10) {
						if pressed {
							if msg.wParam == w.VK_F4 && alt do w.DestroyWindow(platform_hwnd)
							if ODIN_DEBUG && msg.wParam == w.VK_ESCAPE do w.DestroyWindow(platform_hwnd)
							if msg.wParam == w.VK_RETURN && alt do toggle_fullscreen()
							if msg.wParam == w.VK_F11 do toggle_fullscreen()
						}
					}
				case w.WM_QUIT:
					break main_loop
				case:
					w.DispatchMessageW(&msg)
			}
		}
		clock_current: w.LARGE_INTEGER = ---
		w.QueryPerformanceCounter(&clock_current)
		defer clock_previous = clock_current

		renderer.present()

		clock_frame_end: w.LARGE_INTEGER = ---
		w.QueryPerformanceCounter(&clock_frame_end)

		if sleep_is_granular {
			ideal_ms: w.LARGE_INTEGER = 7
			frame_ms := (clock_frame_end - clock_frame_start) / (clock_frequency / 1000)
			if ideal_ms > frame_ms {
				w.Sleep(u32(ideal_ms - frame_ms))
			}
		}
	}
}
