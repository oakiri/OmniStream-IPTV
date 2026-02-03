#!/bin/bash

# OmniStream IPTV - Environment Configuration Script
# This script helps you securely configure Firebase and other API keys
# without hardcoding them in the source code.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         OmniStream IPTV - Environment Setup                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    read -p "⚠️  .env file already exists. Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Existing .env file preserved."
        exit 0
    fi
fi

# Create .env file with secure permissions
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

echo "📝 Enter your Firebase configuration details:"
echo ""

# Firebase Configuration
read -p "Firebase Project ID: " FIREBASE_PROJECT_ID
read -p "Firebase API Key: " FIREBASE_API_KEY
read -p "Firebase Auth Domain: " FIREBASE_AUTH_DOMAIN
read -p "Firebase Storage Bucket: " FIREBASE_STORAGE_BUCKET
read -p "Firebase Messaging Sender ID: " FIREBASE_MESSAGING_SENDER_ID
read -p "Firebase App ID: " FIREBASE_APP_ID

echo ""
echo "🔐 Enter additional API keys (leave blank to skip):"
echo ""

read -p "Sentry DSN (optional): " SENTRY_DSN
read -p "Analytics API Key (optional): " ANALYTICS_API_KEY

# Write to .env file
cat > "$ENV_FILE" << EOF
# Firebase Configuration
FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID
FIREBASE_API_KEY=$FIREBASE_API_KEY
FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN
FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID
FIREBASE_APP_ID=$FIREBASE_APP_ID

# Additional Services
SENTRY_DSN=$SENTRY_DSN
ANALYTICS_API_KEY=$ANALYTICS_API_KEY

# Environment
ENVIRONMENT=development
DEBUG=true
EOF

echo ""
echo "✅ Environment file created successfully!"
echo "📍 Location: $ENV_FILE"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "   1. Never commit .env to version control"
echo "   2. The .env file is already in .gitignore"
echo "   3. Keep your API keys confidential"
echo "   4. Rotate keys regularly"
echo "   5. Use different keys for dev/staging/production"
echo ""
echo "🚀 Next steps:"
echo "   1. Run: flutter pub get"
echo "   2. Run: flutter run"
echo ""
