#!/usr/bin/env bash
set -euo pipefail

# Set JAVA_HOME to JDK 17 (required for Android builds)
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"

export PATH="/home/scottgl/Android/Sdk/platform-tools:/home/scottgl/Android/Sdk/emulator:$PATH"

# Default values
AVD_NAME="test_avd"
EMULATOR_BIN="/home/scottgl/Android/Sdk/emulator/emulator"
ADB_BIN="adb"
APP_PACKAGE="${1:-}"
MAIN_ACTIVITY="${2:-.MainActivity}"

log() {
  echo "[run_emulator] $1"
}

show_usage() {
  cat << EOF
Usage: $0 <package_name> [main_activity]

Arguments:
  package_name    The application package name (e.g., com.example.myapp)
  main_activity   The main activity to launch (default: .MainActivity)

Examples:
  $0 com.example.myapp
  $0 com.example.myapp .ui.MainActivity
  $0 com.mycompany.app SplashActivity

EOF
  exit 1
}

# Check if package name is provided
if [[ -z "$APP_PACKAGE" ]]; then
  log "Error: Application package name is required"
  show_usage
fi

# Verify Java installation
if [[ ! -f "$JAVA_HOME/bin/java" ]]; then
  log "Error: Java not found at $JAVA_HOME/bin/java"
  log "Please ensure JDK 17 is installed at the expected location"
  exit 1
fi

log "Using Java from: $JAVA_HOME"
"$JAVA_HOME/bin/java" -version

log "Resetting adb server"
$ADB_BIN kill-server >/dev/null 2>&1 || true
$ADB_BIN start-server >/dev/null 2>&1 || true

log "Killing existing emulators"
$ADB_BIN devices | awk '/^emulator-/{print $1}' | while read -r device; do
  log "Stopping $device"
  $ADB_BIN -s "$device" emu kill || true
  sleep 1
done

log "Building debug APK"
./gradlew :app:assembleDebug

APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [[ ! -f "$APK_PATH" ]]; then
  log "APK not found at $APK_PATH"
  exit 1
fi

log "Starting emulator $AVD_NAME"
nohup "$EMULATOR_BIN" -avd "$AVD_NAME" -gpu swiftshader_indirect -no-boot-anim >/tmp/emulator-ui.log 2>&1 &

log "Waiting for device"
$ADB_BIN wait-for-device

log "Waiting for boot completion"
until $ADB_BIN shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; do
  sleep 2
done
$ADB_BIN shell input keyevent 82 >/dev/null 2>&1 || true

log "Installing APK"
$ADB_BIN install -r "$APK_PATH"

log "Launching app: $APP_PACKAGE/$MAIN_ACTIVITY"
$ADB_BIN shell am start -n "$APP_PACKAGE/$MAIN_ACTIVITY"

log "Done"
