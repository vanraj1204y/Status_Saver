@echo off
setlocal

cd /d "%~dp0"

echo ==========================================
echo   StatusNest - Clean for Backup
echo ==========================================
echo.
echo This removes generated build artifacts only. It NEVER touches .env,
echo android\key.properties, or any source file under lib\/android\/assets\.
echo.

echo [1/4] Running flutter clean (removes build\ and .dart_tool\)...
call flutter clean
if errorlevel 1 goto :error

echo.
echo [2/4] Removing Gradle's local build cache (android\.gradle)...
if exist "android\.gradle" rmdir /s /q "android\.gradle"

echo.
echo [3/4] Removing leftover Android build output (android\app\build)...
if exist "android\app\build" rmdir /s /q "android\app\build"

echo.
echo [4/4] Removing stray build logs / heap dumps, if any...
del /q "*.log" 2>nul
del /q "android\*.hprof" 2>nul
del /q "build_apk.log" 2>nul

echo.
echo Done. The project folder is now lean enough to zip as a source backup.
echo Run "flutter pub get" (and, for a release, build_release.cmd) before
echo building again after restoring from a backup.
echo.
pause
exit /b 0

:error
echo.
echo Clean FAILED. See the error above for details.
echo.
pause
exit /b 1
