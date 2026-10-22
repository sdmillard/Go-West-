@echo off
setlocal
cd /d "%~dp0"
rem Update first, then rerun this file fresh: the pull may rewrite it while it runs.
if not "%~1"=="updated" (call "%~dp0update.cmd" & cmd /c ""%~f0" updated" & exit /b)
if exist ".tools\godot\Godot_v4.5.1-stable_win64.exe" (
  ".tools\godot\Godot_v4.5.1-stable_win64_console.exe" --headless --path "%~dp0." --editor --import
  if errorlevel 1 exit /b 1
  start "Westward, Probably" ".tools\godot\Godot_v4.5.1-stable_win64.exe" --path "%~dp0."
  exit /b
)
where godot >nul 2>nul
if not errorlevel 1 (
  godot --headless --path "%~dp0." --editor --import
  if errorlevel 1 exit /b 1
  start "Westward, Probably" godot --path "%~dp0."
  exit /b
)
echo Open project.godot in Godot 4.5.1 or later, then press F6 or F5 to play.
pause
