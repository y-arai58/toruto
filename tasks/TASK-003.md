# TASK-003: 加工済み画像の保存（PhotoLibraryService）

- status: done
- priority: high
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

撮影パイプラインの最後、加工済み画像のフォトライブラリ保存を通す。
HEIC（非対応環境は JPEG フォールバック）、位置情報なし、元画像は残さない。

## Acceptance Criteria

- [x] ImageProcessor が HEIC データを生成できる（非対応環境は JPEG フォールバック）
- [x] PhotoLibraryService が addOnly 権限を管理し、PHPhotoLibrary へ保存する
- [x] 撮影後に自動保存され、控えめなサムネイル表示のみ行う（モーダルなし）
- [x] 保存権限拒否時は設定アプリへの導線を表示する
- [x] ViewModel の保存フローの単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] ImageProcessor に makePhotoData（HEIC/JPEG）を追加
- [x] Services/PhotoLibraryService.swift + DefaultPhotoLibraryService
- [x] Info.plist に NSPhotoLibraryAddUsageDescription を追加
- [x] CameraViewModel の保存フロー組み込み + 権限拒否 UI
- [x] MockPhotoLibraryService + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 1-b 後半（保存）として開始 |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
