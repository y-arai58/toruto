# TASK-007: 撮影パラメータの調整（露出補正）

- status: done
- priority: medium
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

撮影パラメータの調整として露出補正（EV -2〜+2）を追加する。
スライダー羅列の加工アプリ UI にはせず、太陽アイコンで出し入れする 1 本のみ。

## Acceptance Criteria

- [x] CameraService で露出補正値を設定できる（デバイスの対応範囲にクランプ）
- [x] 太陽アイコンのトグルで露出スライダーを表示/非表示できる
- [x] カメラ切替後も露出補正値が維持される
- [x] ViewModel の単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] CameraService.setExposureBias + DefaultCameraService 実装
- [x] CameraViewModel.adjustExposure
- [x] CameraView の露出 UI（トグル + スライダー）
- [x] MockCameraService 対応 + テスト

## Notes

- 「撮影パラメータの調整」の解釈として、カメラアプリで最も標準的な露出補正を採用

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 2 として開始 |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
