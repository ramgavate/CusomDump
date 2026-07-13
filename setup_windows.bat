@echo off
setlocal enabledelayedexpansion

echo Setting up mongo-sampler-dump for Windows...
echo.

call :ensure_tool git Git.Git || exit /b 1
call :ensure_tool node OpenJS.NodeJS.LTS || exit /b 1
call :ensure_tool npm OpenJS.NodeJS.LTS || exit /b 1
call :ensure_tool mongoimport MongoDB.DatabaseTools || exit /b 1

echo.
echo Installing project dependencies...
npm install
if errorlevel 1 (
    echo ERROR: npm install failed.
    exit /b 1
)

if not exist ".env" (
    if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo Created .env from .env.example
    ) else (
        echo WARNING: .env.example was not found. Create .env before running export/import.
    )
) else (
    echo .env already exists; leaving it unchanged.
)

if not exist "dump" mkdir "dump"

echo.
echo Setup complete.
echo Next steps:
echo   1. Edit .env with SOURCE_URI, DB_NAME, TARGET_URI, and TARGET_DB.
echo   2. Run: npm run export
echo   3. Run: import_all.bat dump\YOUR_DB_FOLDER
echo.
exit /b 0

:ensure_tool
set "TOOL=%~1"
set "PACKAGE_ID=%~2"

where "%TOOL%" >nul 2>nul
if not errorlevel 1 (
    echo Found %TOOL%.
    exit /b 0
)

echo %TOOL% not found.
where winget >nul 2>nul
if errorlevel 1 (
    echo ERROR: winget is not available. Install %TOOL% manually, then run this script again.
    exit /b 1
)

echo Installing %TOOL% with winget package %PACKAGE_ID%...
winget install --id "%PACKAGE_ID%" --exact --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo ERROR: Failed to install %TOOL%.
    exit /b 1
)

where "%TOOL%" >nul 2>nul
if errorlevel 1 (
    echo Installed %TOOL%, but it is not available in this terminal PATH yet.
    echo Close this terminal, open a new one, and run setup_windows.bat again.
    exit /b 1
)

echo Found %TOOL%.
exit /b 0
