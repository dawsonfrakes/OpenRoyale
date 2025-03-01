@echo off

if not exist .out mkdir .out

where /q cl || call vcvars64.bat || goto :error

cl -Fe.out\RedWheelbarrow.exe -nologo -W4 -WX -Z7 -Oi -J -EHa- -GR- -GS- -Gs0x10000000 -DDEBUG=1^
 platform\main_windows.cpp game\game.cpp kernel32.lib user32.lib ws2_32.lib d3d11.lib d3dcompiler.lib dwmapi.lib winmm.lib^
 -link -incremental:no -nodefaultlib -subsystem:console -entry:WinMainCRTStartup -stack:0x10000000,0x10000000 -heap:0,0 || goto :error

if "%1"=="run" ( .out\RedWheelbarrow.exe
) else if "%1"=="debug" ( start remedybg .out\RedWheelbarrow.exe
) else if "%1"=="doc" ( start qrenderdoc .out\RedWheelbarrow.exe
) else if not "%1"=="" ( echo command '%1' not found & goto :error )

:end
del *.obj 2>nul
exit /b
:error
call :end
exit /b 1
