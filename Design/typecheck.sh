#!/bin/bash
# サンドボックス環境で xcodebuild が使えないため、swift-frontend で型チェックだけ行う。
# 実ビルド・テスト実行は Xcode 側で行うこと（tasks/lessons.md 参照）。
#
# 使い方:
#     bash Design/typecheck.sh          # アプリターゲット
#     bash Design/typecheck.sh --tests  # アプリ + テストターゲット
set -uo pipefail
cd "$(dirname "$0")/.."

SDK=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
TC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
PLATFORM=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer

SOURCES=$(find Toruto -name '*.swift')
if [ "${1:-}" = "--tests" ]; then
    SOURCES="$SOURCES $(find TorutoTests -name '*.swift')"
fi

mkdir -p build/modcache

# shellcheck disable=SC2086
OUTPUT=$(
    "$TC/usr/bin/swift-frontend" -typecheck \
        -sdk "$SDK" \
        -target arm64-apple-ios17.0-simulator \
        -disable-sandbox \
        -module-cache-path "$PWD/build/modcache" \
        -plugin-path "$TC/usr/lib/swift/host/plugins" \
        -plugin-path "$PLATFORM/usr/lib/swift/host/plugins" \
        $SOURCES 2>&1
)

ERRORS=$(echo "$OUTPUT" | grep -E "error:" | grep -vE "^\s")
if [ -n "$ERRORS" ]; then
    echo "$ERRORS"
    echo "TYPECHECK FAILED"
    exit 1
fi

echo "TYPECHECK OK"
