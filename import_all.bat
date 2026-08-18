@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: import_all.bat dump\dbname
    pause
    exit /b 1
)

set "DUMP_DIR=%~1"

if not exist "%DUMP_DIR%" (
    echo ERROR: Dump folder does not exist: %DUMP_DIR%
    pause
    exit /b 1
)

if not exist ".env" (
    echo ERROR: .env was not found. Copy .env.example to .env and update it first.
    pause
    exit /b 1
)

:: Load variables from .env. Comment lines beginning with # are ignored.
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    set "key=%%a"
    if not "!key!"=="" if not "!key:~0,1!"=="#" (
        rem Only accept the variables used by this importer. This also ignores
        rem whitespace-only lines in .env, which otherwise cause batch errors.
        if /i "!key!"=="TARGET_URI" set "TARGET_URI=%%b"
        if /i "!key!"=="TARGET_DB" set "TARGET_DB=%%b"
    )
)

if "%TARGET_URI%"=="" (
    echo ERROR: TARGET_URI is not set in .env
    pause
    exit /b 1
)

if "%TARGET_DB%"=="" (
    echo TARGET_DB not set in .env, using folder name.
    for %%d in ("%DUMP_DIR%") do set "TARGET_DB=%%~nxd"
)

if not exist "%DUMP_DIR%\*.json" (
    echo ERROR: No JSON files found in %DUMP_DIR%
    pause
    exit /b 1
)

echo Importing JSON files from %DUMP_DIR% into:
echo    "%TARGET_URI%/%TARGET_DB%"
echo.

for %%f in ("%DUMP_DIR%\*.json") do (
    set "file=%%~f"
    set "name=%%~nf"
    set "content="
    for /f "usebackq delims=" %%a in ("!file!") do if not defined content set "content=%%a"
    if "!content!"=="[]" (
        echo Skipping !file! because it contains an empty JSON array.
    ) else (
        echo Importing !file! -^> collection !name!
        mongoimport --uri "%TARGET_URI%/%TARGET_DB%" --collection "!name!" --file "!file!" --jsonArray --drop
        if errorlevel 1 (
            echo ERROR: Import failed for !file!
            pause
            exit /b 1
        )
    )
)

echo.
echo All collections imported successfully.
pause
