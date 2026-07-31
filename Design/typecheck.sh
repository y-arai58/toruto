#!/bin/bash
# サンドボックス環境で xcodebuild が使えないため、swift-frontend で型チェックだけ行う。
# 実ビルド・テスト実行は Xcode 側で行うこと（tasks/lessons.md 参照）。
#
# --tests を付けると、アプリのソースから一度 .swiftmodule を作り、
# それを @testable import してテストターゲットも型チェックする
# （テストは Toruto モジュールの実体が無いと `no such module 'Toruto'` になるため）。
#
# 使い方:
#     bash Design/typecheck.sh          # アプリターゲットのみ
#     bash Design/typecheck.sh --tests  # アプリ + テストターゲット
set -uo pipefail
cd "$(dirname "$0")/.."

SDK=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
TC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
PLATFORM=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SIMPLATFORM=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer

mkdir -p build/modcache

APP_SOURCES=$(find Toruto -name '*.swift')

# shellcheck disable=SC2086
APP_OUTPUT=$(
    "$TC/usr/bin/swift-frontend" -typecheck \
        -sdk "$SDK" \
        -target arm64-apple-ios17.0-simulator \
        -disable-sandbox \
        -module-cache-path "$PWD/build/modcache" \
        -plugin-path "$TC/usr/lib/swift/host/plugins" \
        -plugin-path "$PLATFORM/usr/lib/swift/host/plugins" \
        $APP_SOURCES 2>&1
)
APP_ERRORS=$(echo "$APP_OUTPUT" | grep -E "error:" | grep -vE "^\s")
if [ -n "$APP_ERRORS" ]; then
    echo "$APP_ERRORS"
    echo "APP TYPECHECK FAILED"
    exit 1
fi
echo "APP TYPECHECK OK"

if [ "${1:-}" != "--tests" ]; then
    exit 0
fi

mkdir -p build/modout
# shellcheck disable=SC2086
"$TC/usr/bin/swift-frontend" -emit-module -module-name Toruto \
    -sdk "$SDK" -target arm64-apple-ios17.0-simulator -disable-sandbox \
    -module-cache-path "$PWD/build/modcache" \
    -plugin-path "$TC/usr/lib/swift/host/plugins" \
    -plugin-path "$PLATFORM/usr/lib/swift/host/plugins" \
    -emit-module-path "$PWD/build/modout/Toruto.swiftmodule" \
    -enable-testing \
    $APP_SOURCES > /dev/null 2>&1

TEST_SOURCES=$(find TorutoTests -name '*.swift')
# shellcheck disable=SC2086
TEST_OUTPUT=$(
    "$TC/usr/bin/swift-frontend" -typecheck \
        -sdk "$SDK" -target arm64-apple-ios17.0-simulator -disable-sandbox \
        -module-cache-path "$PWD/build/modcache" \
        -plugin-path "$TC/usr/lib/swift/host/plugins" \
        -plugin-path "$TC/usr/lib/swift/host/plugins/testing" \
        -plugin-path "$PLATFORM/usr/lib/swift/host/plugins" \
        -F "$SIMPLATFORM/Library/Frameworks" \
        -I "$PWD/build/modout" \
        $TEST_SOURCES 2>&1
)
TEST_ERRORS=$(echo "$TEST_OUTPUT" | grep -E "error:" | grep -vE "^\s")
if [ -n "$TEST_ERRORS" ]; then
    echo "$TEST_ERRORS"
    echo "TESTS TYPECHECK FAILED"
    exit 1
fi
echo "TESTS TYPECHECK OK"
