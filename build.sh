#!/bin/bash
set -e

# 1. Install Flutter
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"

# 2. Configure Flutter
echo "Configuring Flutter..."
flutter config --enable-web
flutter pub get

# 3. Inject environment variables
echo "Inserting environment variables..."
sed -i "s|V_GROQ_URL|$GROQ_API_URL|g" web/index.html
sed -i "s|V_GROQ_KEY|$GROQ_API_KEY|g" web/index.html
sed -i "s|V_AI_MODEL|$AI_MODEL_NAME|g" web/index.html

# 4. Build
echo "Building Flutter Web..."
flutter build web --release --base-href "/"

# 5. SPA routing for Cloudflare Pages
echo "/* /index.html 200" > build/web/_redirects
