# TASK-023: 起動体験の改善（起動ロゴ + 体感待ち時間の短縮）

- status: in-progress
- priority: high
- started_at: 2026-07-30

## Goal

「アプリ起動までが長い」という実機フィードバックへの対応。

計測できる遅延を削りつつ、削れない分（カメラのハードウェア起動）は
起動ロゴのアニメーションで体感待ち時間を短くする。

## 原因の切り分け

| # | 原因 | 影響 | 対処 |
|---|---|---|---|
| 1 | `AVCaptureSession.startRunning()` | 実機で〜1 秒。支配的 | 短縮不可。隠す |
| 2 | Launch Screen が無地（`UILaunchScreen_Generation`） | 空白 + ライトモード端末で白→黒のフラッシュ | storyboard 化してロゴ表示 |
| 3 | `status == .running` でもプレビューは未到達 | 「UI は出たのに映像は黒」 | 初フレーム到達を退場条件にする |
| 4 | `DefaultImageProcessor` が init で `CIContext` を生成 | 起動時に数十〜数百 ms。撮影時しか使わない | 初回利用時に遅延生成 |
| 5 | `CIContext(mtlDevice:)` + 初回フィルタのシェーダ JIT | 1 フレーム目が特に遅い | オーバーレイの退場で吸収 |

## Acceptance Criteria

- [x] 起動直後から Toruto のロゴが表示され、白い画面が一瞬も出ない
- [x] 起動画面（storyboard）から SwiftUI のオーバーレイへ継ぎ目なく繋がる
- [x] オーバーレイはプレビューの初フレーム到達で退場する（映像が出る前に消えない）
- [x] カメラが応答しない場合も 4 秒でオーバーレイが外れる
- [x] 権限拒否・カメラ利用不可のときは待たずにオーバーレイが外れる
- [x] `CIContext` の生成が起動パスから外れている
- [x] `hasPreviewFrame` の単体テストを追加
- [ ] swiftc 型チェック通過 + 実機で起動の体感を確認

## Sub Tasks

- [x] `Design/generate_launch_logo.py`（透過ロゴ 100x128pt を 1x/2x/3x で生成）
- [x] `LaunchLogo.imageset` / `LaunchBackground.colorset` 追加
- [x] `Toruto/Resources/LaunchScreen.storyboard` 追加
- [x] `INFOPLIST_KEY_UILaunchScreen_Generation` → `INFOPLIST_KEY_UILaunchStoryboardName`
- [x] `LaunchOverlay` 追加（呼吸アニメーション + スケールアップ退場）
- [x] `CameraViewModel.hasPreviewFrame` 追加（初フレームのみ MainActor へ通知）
- [x] `CameraView` にオーバーレイを組み込み
- [x] `DefaultImageProcessor` の `CIContext` を遅延生成に変更
- [x] docs/ui_guideline.md に起動体験の節を追加

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | 実機フィードバック「起動までが長い」 |
| 2026-07-30 | note | サンドボックスから xcodebuild / ibtool が実行できず、storyboard のコンパイル検証は未実施（XML 構文のみ確認） |
