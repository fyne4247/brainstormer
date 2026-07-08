@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ============================================
echo  Brainstormer workspace - setup wizard (Windows)
echo ============================================
echo This checks for the tools this workspace uses and offers to install
echo anything missing. Nothing is installed without you saying yes.
echo.

where winget >nul 2>nul
if errorlevel 1 (
    set HAVE_WINGET=0
    echo NOTE: winget was not found, so this script can't install things
    echo automatically. Manual download links are given as a fallback.
) else (
    set HAVE_WINGET=1
)
echo.

echo ---- Required ----
echo.

REM ---- git ----
echo git - version control. Every project in this workspace is its own git
echo repo; saving progress and the auto-export snapshots both depend on it.
where git >nul 2>nul
if errorlevel 1 (
    echo   git was not found.
    set /p REPLY="Install git now? [Y/n] "
    if /i "!REPLY!"=="" set REPLY=Y
    if /i "!REPLY!"=="Y" (
        if "!HAVE_WINGET!"=="1" (
            winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
            echo   Installed. Open a new terminal window afterward so PATH updates.
        ) else (
            echo   Download it from: https://git-scm.com/downloads/win
        )
    ) else (
        echo   Skipping git. The workspace's save/export features won't work without it.
    )
) else (
    echo   [OK] git is already installed.
    git --version
)
echo.

REM ---- Claude Code ----
echo Claude Code - the CLI this whole workspace runs on (claude --agent muse).
where claude >nul 2>nul
if errorlevel 1 (
    echo   Claude Code was not found.
    set /p REPLY="Install Claude Code now? [Y/n] "
    if /i "!REPLY!"=="" set REPLY=Y
    if /i "!REPLY!"=="Y" (
        echo   Running the native installer...
        curl -fsSL https://claude.ai/install.cmd -o "%TEMP%\claude-install.cmd"
        call "%TEMP%\claude-install.cmd"
        del "%TEMP%\claude-install.cmd" >nul 2>nul
        echo   If 'claude' isn't recognized yet, open a new terminal window.
    ) else (
        echo   Skipping Claude Code. Nothing else in this workspace will run without it.
    )
) else (
    echo   [OK] Claude Code is already installed.
    claude --version
)
echo.

echo ---- Optional ----
echo.

REM ---- Python 3 ----
echo Python 3 - only used for the auto-export snapshots (scripts\flatten_project.py),
echo which turn each project's kb\ into one combined exports\^<project^>.md file
echo after every save. Everything else in the workspace works fine without it.
where python >nul 2>nul
if errorlevel 1 (
    set /p REPLY="Install Python 3? [y/N] "
    if /i "!REPLY!"=="" set REPLY=N
    if /i "!REPLY!"=="Y" (
        if "!HAVE_WINGET!"=="1" (
            winget install --id Python.Python.3.12 -e --accept-package-agreements --accept-source-agreements
            echo   Installed. Open a new terminal window afterward so PATH updates.
        ) else (
            echo   Download it from: https://python.org/downloads
        )
    ) else (
        echo   Skipping - you just won't get exports\*.md snapshots after saves.
    )
) else (
    echo   [OK] Python is already installed.
    python --version
)
echo.

REM ---- pandoc ----
echo pandoc - only used by /setup when you point it at writing samples that
echo aren't plain text (.docx, .rtf, .odt), so it can convert them for the
echo style-reference kb. If you only ever use .txt/.md samples, skip this.
where pandoc >nul 2>nul
if errorlevel 1 (
    set /p REPLY="Install pandoc? [y/N] "
    if /i "!REPLY!"=="" set REPLY=N
    if /i "!REPLY!"=="Y" (
        if "!HAVE_WINGET!"=="1" (
            winget install --id JohnMacFarlane.Pandoc -e --accept-package-agreements --accept-source-agreements
            echo   Installed. Open a new terminal window afterward so PATH updates.
        ) else (
            echo   Download it from: https://pandoc.org/installing.html
        )
    ) else (
        echo   Skipping - /setup will just ask for plain-text exports of any samples instead.
    )
) else (
    echo   [OK] pandoc is already installed.
    pandoc --version
)
echo.

echo ---- Finishing up ----
echo.
echo Windows .bat files don't need an executable bit set, so there's nothing
echo to chmod - brainstormer.bat is ready to double-click as-is.
echo.
echo All done. Double-click brainstormer.bat to start writing.
echo.
pause
