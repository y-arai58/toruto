# TASK-001: Phase 1-a カメラ起動 → プレビュー → シャッター

- status: done
- priority: high
- started_at: 2026-07-27
- completed_at: 2026-07-30

## Goal

撮影パイプラインの縦串の前半（カメラ起動 → リアルタイムプレビュー → シャッター撮影）を通す。
Crop / フィルター / 保存は Phase 1-b（TASK-002 以降）。

## Acceptance Criteria

- [x] Xcode プロジェクト（iOS 17+ / SwiftUI / iPhone 専用）が作成されている
- [x] カメラ権限をリクエストし、拒否時は設定アプリへの導線を表示する
- [x] AVCaptureSession が起動し、MTKView + Metal バック CIContext でプレビュー表示できる
- [x] シャッターで静止画を撮影できる（視覚 + 触覚フィードバック付き）
- [x] CameraViewModel の単体テストがある（モック Service 注入）
- [x] シミュレータ向けビルドが通る（ユーザー環境で xcodebuild test 通過を確認）

## Sub Tasks

- [x] プロジェクト雛形（pbxproj・スキーム・Assets・.gitignore）
- [x] CameraService プロトコル + DefaultCameraService（権限・セッション・フレーム供給・撮影）
- [x] CameraPreviewView（MTKView + CIContext）
- [x] CameraViewModel / CameraView / ShutterButton
- [x] MockCameraService + CameraViewModelTests

## Notes

- テストディレクトリは docs/architecture.md の `Toruto/Tests/` ではなく、Xcode 標準の
  ルート直下 `TorutoTests/` に配置（FileSystemSynchronizedRootGroup でターゲット分離するため）
- Foundation の atomic write（/var/folders）が sandbox で遮断されるため、この環境では
  xcodebuild が動かない。検証は `swiftc -typecheck`（アプリ + テスト）+ `plutil -lint` で実施

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-27 | created | Phase 1-a 開始 |
| 2026-07-27 | started | プロジェクト雛形の作成から着手 |
| 2026-07-27 | note | 実装完了。swiftc 型チェック（app/tests）通過 |
| 2026-07-27 | blocked | xcodebuild が sandbox 制約で実行不可。ユーザー環境でのビルド・テスト実行待ち |
| 2026-07-30 | completed | ユーザー環境でビルド・テスト通過を確認 |
