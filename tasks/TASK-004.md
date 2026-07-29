# TASK-004: カメラプリセット切り替え UI

- status: done
- priority: high
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

プリセット切り替えを 1 アクションで行える UI を追加し、
プレビューのフィルターが切り替えに即時追従するようにする。

## Acceptance Criteria

- [x] 上部に現在のプリセット名が表示される
- [x] 横スクロールのプリセット選択 UI（タップ領域 44pt 以上）で 1 アクション切替できる
- [x] 切り替えるとプレビューのフィルターが即時変わる（再購読なしで追従）
- [x] 切り替え時に触覚フィードバックがある
- [x] ViewModel の切替ロジックの単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] CameraViewModel.selectPreset + プレビューパラメータのライブ反映
- [x] Components/PresetSelector.swift（横スクロールチップ）
- [x] CameraView への組み込み（上部プリセット名 + 選択 UI + Haptics）
- [x] MockCameraService のフレーム供給対応 + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 1 残り（プリセット切替）として開始 |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
