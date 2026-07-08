@echo off
REM Launcher for the Brainstormer creative-writing workspace (Windows).
REM Double-click this file in Explorer to start a muse session.
REM
REM NOTE: this wrapper has not been tested on an actual Windows machine.
REM It just tries to find something that can run a bash script (Git Bash
REM or WSL) and hands off to Brainstormer.sh, which has the real logic.
REM If double-clicking this does nothing or errors out, try running one
REM of these manually from a terminal in this folder instead:
REM   "C:\Program Files\Git\bin\bash.exe" Brainstormer.sh
REM   wsl bash Brainstormer.sh

cd /d "%~dp0"

where wsl >nul 2>nul
if %errorlevel%==0 (
    wsl bash Brainstormer.sh
    goto :end
)

if exist "%ProgramFiles%\Git\bin\bash.exe" (
    "%ProgramFiles%\Git\bin\bash.exe" Brainstormer.sh
    goto :end
)

if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
    "%ProgramFiles(x86)%\Git\bin\bash.exe" Brainstormer.sh
    goto :end
)

echo Couldn't find WSL or Git Bash on this machine.
echo Brainstormer needs one of them to run. Install either:
echo   - WSL:      https://learn.microsoft.com/windows/wsl/install
echo   - Git Bash: https://git-scm.com/downloads
pause

:end
pause
