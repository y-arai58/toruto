# TASK-009: フラッシュエフェクト

- status: in-progress
- priority: medium
- started_at: 2026-07-30

## Goal

フラッシュ撮影を追加する。背面は実フラッシュ（デバイスが対応する場合）、
前面などフラッシュ非搭載時は画面全体を白く光らせるスクリーンフラッシュで代替する。

## Acceptance Criteria

- [x] 稲妻アイコンでフラッシュの ON/OFF を切り替えられる
- [x] ON のとき背面撮影で実フラッシュが発光する（対応デバイスのみ）
- [x] ON のときスクリーンフラッシュ演出が強くなる（前面でも効果がある）
- [x] ViewModel の単体テストがある
- [ ] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] CameraService.setFlashEnabled + 撮影時の flashMode 適用
- [x] CameraViewModel.toggleFlash
- [x] CameraView の稲妻トグル + スクリーンフラッシュ強化
- [x] MockCameraService 対応 + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 2 として開始 |
