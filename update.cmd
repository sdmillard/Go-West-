@echo off
rem Fast-forwards a clean master checkout to GitHub's master. Never touches local edits or other branches.
setlocal
cd /d "%~dp0"
where git >nul 2>nul || (echo Skipping update: Git is not installed.& exit /b 0)
set "branch="
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "branch=%%b"
if not "%branch%"=="master" (echo Skipping update: on branch "%branch%", not master.& exit /b 0)
for /f %%c in ('git status --porcelain --untracked-files^=no 2^>nul') do (echo Skipping update: there are local changes.& exit /b 0)
git pull --ff-only --quiet origin master && (echo Up to date with GitHub.& exit /b 0) || (echo Update failed; using the copy already here.& exit /b 0)
