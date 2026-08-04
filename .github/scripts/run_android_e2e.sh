#!/usr/bin/env bash

set -Eeuo pipefail

exec > >(tee -a e2e-run.log) 2>&1

echo "Flutter: $(command -v flutter)"
flutter --version
echo "Android devices:"
adb devices -l

device="$(adb get-serialno)"
test -n "${device}"
test "${device}" != "unknown"

# 10.0.2.2 is the Android emulator alias for the host loopback interface.
# It keeps the app-to-emulator connection independent from adb reverse rules.
flutter_bin="$(command -v flutter)"
test -x "${flutter_bin}"

flutter_command="${flutter_bin} test integration_test/app_test.dart"
flutter_command+=" -d ${device}"
flutter_command+=" --reporter expanded"
flutter_command+=" --dart-define=USE_FIREBASE_EMULATORS=true"
flutter_command+=" --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2"

npx --yes firebase-tools@15.17.0 emulators:exec \
  --only auth,firestore \
  --project stronger-f7c9c \
  "bash -o pipefail -c '${flutter_command} 2>&1 | tee e2e-flutter.log'"
