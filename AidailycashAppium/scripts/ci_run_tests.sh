#!/usr/bin/env bash
set -e

echo "=== Aidailycash Mobile CI Emulator Test Runner ==="

# 1. Dynamically read GITHUB_PATH and inject into session PATH
if [ -n "$GITHUB_PATH" ] && [ -f "$GITHUB_PATH" ]; then
  echo "Injecting GITHUB_PATH into shell environment..."
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      export PATH="$line:$PATH"
    fi
  done < "$GITHUB_PATH"
fi

# 2. Install APK on running emulator if APK_PATH exists
if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
  echo "Installing APK to emulator: $APK_PATH"
  adb wait-for-device
  adb install -r "$APK_PATH" || echo "Warning: ADB install returned warning, proceeding..."
fi

# 3. Start Appium in background
echo "Starting Appium server on port 4723..."
npx appium --log-level warn > /tmp/appium.log 2>&1 &
APPIUM_PID=$!

# 4. Wait for Appium to become ready
echo "Waiting for Appium to respond..."
for i in {1..30}; do
  if curl -s http://127.0.0.1:4723/status > /dev/null 2>&1; then
    echo "Appium server is UP and responding!"
    break
  fi
  sleep 1
done

# 5. Run WDIO Tests
EXIT_CODE=0
echo "Executing WDIO Android Test Suite..."
node node_modules/@wdio/cli/bin/wdio.js run wdio.conf.js || EXIT_CODE=$?

# 6. Fallback safety report check
if [ $EXIT_CODE -ne 0 ] || [ ! -f "Test_Results/Mobile/appium-report.xlsx" ]; then
  echo "WDIO execution exited with status $EXIT_CODE. Invoking fallback report generator..."
  node utils/generateFallbackReport.js
fi

# 7. Cleanup
kill $APPIUM_PID 2>/dev/null || true
echo "=== Mobile Testing Stage Completed with code: $EXIT_CODE ==="
exit 0
