version (Windows) {
	import basic.windows : HINSTANCE, HWND, HDC;

	__gshared HINSTANCE platform_hinstance;
	__gshared HWND platform_hwnd;
	__gshared HDC platform_hdc;
	__gshared ushort[2] platform_size;
}
