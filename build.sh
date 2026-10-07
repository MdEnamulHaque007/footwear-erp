#!/bin/bash
set -e

FLUTTER_SDK_PATH="$HOME/flutter"

# Flutter ডাউনলোড (যদি আগে থেকে না থাকে)
if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Downloading Flutter SDK..."
  git clone --branch stable https://github.com/flutter/flutter.git $FLUTTER_SDK_PATH
fi

# PATH-এ Flutter যোগ করা
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Flutter সেটআপ
flutter config --enable-web
flutter doctor

# ডিপেন্ডেন্সি ইনস্টল
flutter pub get

# ওয়েব বিল্ড
flutter build web --release
