#!/bin/bash

# 1. Install Flutter (since Vercel doesn't have it by default)
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Verify and Config
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
