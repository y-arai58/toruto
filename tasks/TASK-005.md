# TASK-005: UI 改善（前面/背面切替・仕上げ）

- status: done
- priority: high
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

Phase 1 の仕上げ。bottomBar に予約してあった前面/背面切替を実装し、
撮影画面の細部を UI ガイドラインに沿って磨く。

## Acceptance Criteria

- [x] 前面/背面カメラを 1 タップで切り替えられる（前面はプレビューをミラー表示）
- [x] 切替ボタンはタップ領域 44pt 以上・切替中は連打不可
- [x] 中央フレームの境界が視認できる（保存領域の明示を強化）
- [x] ViewModel の切替ロジックの単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] CameraService.switchCamera（入力の付け替え・ミラーリング設定）
- [x] CameraViewModel.switchCamera + CameraView の切替ボタン
- [x] 中央フレームの枠線
- [x] MockCameraService 対応 + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 1 仕上げとして開始 |
| 2026-07-30 | completed | PR #6 マージ済み |
