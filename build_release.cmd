@echo off
setlocal

cd /d "%~dp0"

echo ==========================================
echo   StatusNest - Release Build
echo ==========================================

if not exist ".env" (
    echo.
    echo ERROR: .env file not found in project root.
    echo Copy .env.example to .env and fill in the real values first.
    echo.
    pause
    exit /b 1
)

echo.
echo [1/6] Cleaning previous build files (flutter clean)...
echo       (only removes build/, .dart_tool/ etc - never touches your source code)
call flutter clean
if errorlevel 1 goto :error

echo.
echo [2/6] Fetching dependencies (flutter pub get)...
call flutter pub get
if errorlevel 1 goto :error

echo.
echo [3/6] Refreshing Privacy Policy / Terms of Use (dart run tool/fetch_legal_documents.dart)...
call dart run tool/fetch_legal_documents.dart
if errorlevel 1 goto :error

echo.
echo [4/6] Building release APK...
call flutter build apk --release --dart-define-from-file=.env
if errorlevel 1 goto :error

echo.
echo [5/6] Building release App Bundle (AAB) for Play Store...
call flutter build appbundle --release --dart-define-from-file=.env
if errorlevel 1 goto :error

echo.
echo [6/6] Done.
echo.
echo Release APK created at:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo Release App Bundle (for Play Store upload) created at:
echo   build\app\outputs\bundle\release\app-release.aab
echo.
pause
exit /b 0

:error
echo.
echo Build FAILED. See the error above for details.
echo.
pause
exit /b 1
