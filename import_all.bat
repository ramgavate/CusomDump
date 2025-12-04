@echo off
setlocal enabledelayedexpansion

:: Load variables from .env
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    if not "%%a"=="" (
        set "%%a=%%b"
    )
)

:: Check required variables
if "%TARGET_URI%"=="" (
    echo ERROR: TARGET_URI is not set in .env
    pause
    exit /b 1
)

if "%TARGET_DB%"=="" (
    echo TARGET_DB not set in .env, using folder name.
    set TARGET_DB=%1
)

:: Validate dump folder argument
if "%1"=="" (
    echo Usage: import_all.bat dump\dbname
    pause
    exit /b 1
)

set DUMP_DIR=%1

echo 🚀 Importing JSON files from %DUMP_DIR% into:
echo    %TARGET_URI%/%TARGET_DB%
echo.

for %%f in (%DUMP_DIR%\*.json) do (
    set file=%%f
    set name=%%~nf
    echo ➡ Importing !file! → collection !name!
    mongoimport --uri "%TARGET_URI%/%TARGET_DB%" --collection "!name!" --file "!file!" --jsonArray --drop
)

echo.
echo 🎉 All collections imported successfully!
pause
