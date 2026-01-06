@echo off
REM OmniStream IPTV - Environment Configuration Script (Windows)
REM This script helps you securely configure Firebase and other API keys

setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
set "ENV_FILE=%PROJECT_ROOT%\.env"

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║         OmniStream IPTV - Environment Setup (Windows)          ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM Check if .env already exists
if exist "%ENV_FILE%" (
    set /p OVERWRITE="⚠️  .env file already exists. Overwrite? (y/n): "
    if /i not "!OVERWRITE!"=="y" (
        echo Setup cancelled. Existing .env file preserved.
        exit /b 0
    )
)

echo 📝 Enter your Firebase configuration details:
echo.

set /p FIREBASE_PROJECT_ID="Firebase Project ID: "
set /p FIREBASE_API_KEY="Firebase API Key: "
set /p FIREBASE_AUTH_DOMAIN="Firebase Auth Domain: "
set /p FIREBASE_STORAGE_BUCKET="Firebase Storage Bucket: "
set /p FIREBASE_MESSAGING_SENDER_ID="Firebase Messaging Sender ID: "
set /p FIREBASE_APP_ID="Firebase App ID: "

echo.
echo 🔐 Enter additional API keys (leave blank to skip):
echo.

set /p SENTRY_DSN="Sentry DSN (optional): "
set /p ANALYTICS_API_KEY="Analytics API Key (optional): "

REM Write to .env file
(
    echo # Firebase Configuration
    echo FIREBASE_PROJECT_ID=%FIREBASE_PROJECT_ID%
    echo FIREBASE_API_KEY=%FIREBASE_API_KEY%
    echo FIREBASE_AUTH_DOMAIN=%FIREBASE_AUTH_DOMAIN%
    echo FIREBASE_STORAGE_BUCKET=%FIREBASE_STORAGE_BUCKET%
    echo FIREBASE_MESSAGING_SENDER_ID=%FIREBASE_MESSAGING_SENDER_ID%
    echo FIREBASE_APP_ID=%FIREBASE_APP_ID%
    echo.
    echo # Additional Services
    echo SENTRY_DSN=%SENTRY_DSN%
    echo ANALYTICS_API_KEY=%ANALYTICS_API_KEY%
    echo.
    echo # Environment
    echo ENVIRONMENT=development
    echo DEBUG=true
) > "%ENV_FILE%"

echo.
echo ✅ Environment file created successfully!
echo 📍 Location: %ENV_FILE%
echo.
echo ⚠️  IMPORTANT SECURITY NOTES:
echo    1. Never commit .env to version control
echo    2. The .env file is already in .gitignore
echo    3. Keep your API keys confidential
echo    4. Rotate keys regularly
echo    5. Use different keys for dev/staging/production
echo.
echo 🚀 Next steps:
echo    1. Run: flutter pub get
echo    2. Run: flutter run
echo.

pause
