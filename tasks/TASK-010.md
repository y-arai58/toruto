# TASK-010: 日付スタンプ

- status: done
- priority: medium
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

フィルムカメラ風のオレンジ色の日付スタンプ（例: '26 7 30）を保存画像の右下に焼き込む。
ON/OFF はトグルで切り替えられる。

## Acceptance Criteria

- [x] トグル ON のとき保存画像の右下に日付スタンプが焼き込まれる
- [x] スタンプは画像サイズに応じてスケールする（解像度によらず同じ見た目）
- [x] ON/OFF はアプリ再起動後も保持される（UserDefaults）
- [x] ImageProcessor / ViewModel の単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] ImageProcessor.stampDate（CITextImageGenerator + オレンジ着色 + 右下合成）
- [x] CameraViewModel の日付スタンプトグル + 撮影パスへの組み込み
- [x] CameraView のカレンダーアイコントグル
- [x] Mock 対応 + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 2 として開始 |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
