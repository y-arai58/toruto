# Lessons

## 2026-07-27: @Observable な ViewModel は View の init のデフォルト引数で生成できない

- `@MainActor @Observable` な ViewModel を `init(viewModel: CameraViewModel = CameraViewModel())`
  のようにデフォルト引数で生成すると、デフォルト引数は nonisolated コンテキストで評価されるため
  actor 分離エラーになる
- 対処: 引数を Optional にして `init(viewModel: CameraViewModel? = nil)` とし、
  `@MainActor` な init 本体の中で `viewModel ?? CameraViewModel()` と生成する

## 2026-07-27: この開発環境（sandbox）では xcodebuild / simctl が動かない

- Foundation の atomic write（/var/folders）と CoreSimulatorService 接続が遮断されるため、
  xcodebuild はセッション内（`!` プレフィックス含む）では常に失敗する
- 検証の代替手段:
  - コンパイル: `swiftc -typecheck -target arm64-apple-ios17.0-simulator -Xfrontend -disable-sandbox`
    （Swift Testing のテストは `-plugin-path .../swift/host/plugins/testing` を追加）
  - pbxproj: `plutil -lint`、scheme: `xmllint --noout`
- 実ビルド・テスト実行はユーザーの Xcode / 通常ターミナルに依頼する
