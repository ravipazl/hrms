@echo off
echo ===============================================
echo  HRMS Flutter Requisition Management Setup
echo ===============================================
echo.

echo Checking Flutter installation...
flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

echo.
echo Checking current directory...
if not exist "pubspec.yaml" (
    echo ERROR: Please run this script from the Flutter project directory
    echo Current directory: %CD%
    echo Expected: D:\hrms_final\hrms
    pause
    exit /b 1
)

echo.
echo Installing dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Checking for Chrome (for web development)...
where chrome >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Chrome not found in PATH
    echo You may need to specify the browser manually
)

echo.
echo ===============================================
echo  Setup Complete!
echo ===============================================
echo.
echo Available commands:
echo   flutter run -d chrome          # Run in Chrome
echo   flutter run -d edge             # Run in Edge  
echo   flutter build web              # Build for production
echo.
echo Make sure Django backend is running:
echo   cd D:\hrms_final\srmc_requisition_workflow
echo   python manage.py runserver
echo.
echo Press any key to launch the app in Chrome...
pause >nul

echo Launching Flutter app...
flutter run -d chrome

pause
