# Lessons

## 2026-07-30: 実機確認は Release + デバッガなしで行う

- Debug は `SWIFT_OPTIMIZATION_LEVEL = -Onone`。このアプリは毎フレーム
  Core Image のフィルタチェーンを組んで Metal で描くため、
  最適化なし + LLDB 接続だと実機でも数 fps まで落ちて「固まった」ように見える
- 端末側でアプリをタスクキルすると LLDB セッションが切れ、
  Xcode が Run アクション全体を失敗として表示する。
  **これはコンパイルエラーではない**（Report navigator でエラー 0 件なら実行セッションが切れただけ）
- そのため scheme の LaunchAction は Release + デバッガなしにしてある
  （`selectedDebuggerIdentifier = ""`）
- 代わりに Xcode のコンソールに `print` が出なくなる。
  ログが要るときは一時的にデバッガを戻すか、`Logger` を使って Console.app で見る
- TestAction は Debug のままなので `⌘U` は今まで通り

## 2026-07-30: 設定した値ではなく読み戻した実測値を使う（TASK-024）

- `AVCaptureConnection` への `videoRotationAngle` / `isVideoMirrored` は、
  入力を張り替えた直後だと**エラーも警告もなく適用されない**ことがある
- `guard let connection else { continue }` と `if isVideoRotationAngleSupported`
  の組み合わせは、失敗を 2 段構えで握りつぶすので特に危険
- **「設定が効かないなら既定値のはず」は成り立たない。**
  前面カメラでは初回構成（背面）で設定した 90 度が接続に残ったまま届き、
  そこにソフト側でもう 90 度足して二重回転していた。
  0 に戻す設定も同じ理由で効かず、修正のつもりが不具合の一部になった
- 適用されたか分からない設定を前提に計算しないこと。
  `captureOutput` に渡ってくる `connection` から**実測値を読み戻し**、
  不足分だけを `CIImage.oriented(_:)` で補えば、設定の成否に依存しなくなる
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
  - コンパイル: `bash Design/typecheck.sh`（アプリのみ）/ `bash Design/typecheck.sh --tests`（+ テスト）
    - テストは `@testable import Toruto` が要るため、アプリのソースから一度
      `-emit-module` で `.swiftmodule` を作り、それを `-I` で読ませてから型チェックする
    - Swift Testing の macro plugin は `.../usr/lib/swift/host/plugins/testing`
      （`plugins` 直下ではなくその一段下）にある。ここを外すと `TestingMacros` が見つからず失敗する
  - pbxproj: `plutil -lint`、scheme: `xmllint --noout`
- 実ビルド・テスト実行はユーザーの Xcode / 通常ターミナルに依頼する
