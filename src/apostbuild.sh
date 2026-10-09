#!/usr/bin/env bash
set -euo pipefail

ANDROID_DIR=build/Android
ANDROID_OUTPUT_DIR=$ANDROID_DIR/app/src/main/assets

# cp -rv models $ANDROID_OUTPUT_DIR
# cp -rv maps $ANDROID_OUTPUT_DIR
# cp -rv textures $ANDROID_OUTPUT_DIR
# cp -rv shaders $ANDROID_OUTPUT_DIR

$ANDROID_DIR/gradlew -p $ANDROID_DIR assembleDebug
mv -v $ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk cucafps.apk
