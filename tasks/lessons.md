# Lessons

## 2026-07-30: AVCaptureConnection の向き設定に頼らない（TASK-024）

- `AVCaptureConnection` への `videoRotationAngle` / `isVideoMirrored` は、
  入力を張り替えた直後だと接続が取れなかったり回転角が非対応だったりして、
  **エラーも警告もなく適用されない**ことがある
- `guard let connection else { continue }` と `if isVideoRotationAngleSupported`
  の組み合わせは、失敗を 2 段構えで握りつぶすので特に危険
- 向きの補正は `CIImage.oriented(_:)` でコード側の一箇所に集約する。
  AVFoundation の挙動に依存しなくなり、単体テストも書ける
- 下の TASK-019 の教訓（commit 後に設定する）は**この不具合の原因ではなかった**。
  症状が 1 ミリも変わらないときは、タイミングではなく
  「そもそも届いているか」を疑うこと

## 2026-07-30: AVCaptureSession の入力付け替え後の接続設定は commit 後に行う

- `beginConfiguration` 中に入力を付け替えた場合、新しい入力と出力の接続
  （AVCaptureConnection）は `commitConfiguration` で確定する
- そのため `videoRotationAngle` / `isVideoMirrored` などの接続設定を commit 前に
  行うと新接続に適用されず、前面カメラのプレビューが横向きになる不具合になった
- 接続への設定は必ず `commitConfiguration` の後に行う（TASK-019 で修正）
- 初回構成は「出力追加時に既存入力との接続が即座に作られる」ため顕在化しない。
  切替系の動作は必ず実機で確認する

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
