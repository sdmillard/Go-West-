@echo off
setlocal
set "APPDATA=%~dp0.tools\rafting-practice-userdata"
if not exist "%~dp0.tools\godot\Godot_v4.5.1-stable_win64_console.exe" (
  echo The portable Godot runtime is missing from .tools\godot.
  pause
  exit /b 1
)
"%~dp0.tools\godot\Godot_v4.5.1-stable_win64_console.exe" --path "%~dp0." --script res://tests/play_rafting_prototype.gd
endlocal
