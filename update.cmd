@echo off
rem Fast-forwards a clean master checkout to GitHub's master. Never touches local edits or other branches;
rem only removes untracked Godot .uid/.import files that the update brings tracked copies of.
setlocal
cd /d "%~dp0"
where git >nul 2>nul || (echo Skipping update: Git is not installed.& exit /b 0)
set "branch="
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "branch=%%b"
if not "%branch%"=="master" (echo Skipping update: on branch "%branch%", not master.& exit /b 0)
for /f %%c in ('git status --porcelain --untracked-files^=no 2^>nul') do (echo Skipping update: there are local changes.& exit /b 0)
git fetch --quiet origin master || (echo Update failed; using the copy already here.& exit /b 0)
rem Godot writes .uid/.import files for new scripts before they reach GitHub; drop untracked copies the update would overwrite.
for /f "delims=" %%f in ('git diff --name-only --diff-filter=A HEAD FETCH_HEAD -- "*.uid" "*.import" 2^>nul') do git clean -fq -- "%%f" >nul 2>nul
git merge --ff-only --quiet FETCH_HEAD && (echo Up to date with GitHub.& exit /b 0) || (echo Update failed; using the copy already here.& exit /b 0)
