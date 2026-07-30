# TASK-012: シャッター音切り替え

- status: done
- priority: low
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

シャッター音をクラシック / デジタル / フィルムから選べるようにする。
選択は永続化し、撮影時に再生する。

## Acceptance Criteria

- [x] スピーカーアイコンのメニューからシャッター音を選べる
- [x] 撮影時に選択中の音が鳴る（クラシックはシステム音 1108）
- [x] 選択はアプリ再起動後も保持される（UserDefaults）
- [x] ViewModel の単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] Models/ShutterSound.swift（enum + CaseIterable）
- [x] Resources/Sounds/ に音源（digital / film）
- [x] Services/ShutterSoundPlayer.swift + SystemShutterSoundPlayer
- [x] SettingsStore に shutterSound を追加
- [x] CameraViewModel / CameraView 組み込み
- [x] Mock 対応 + テスト

## Notes

- digital / film の音源は合成したプレースホルダ。差し替えは同名 wav を置くだけ
- 日本向けデバイスは OS 側の強制シャッター音が別途鳴る場合がある

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 3 として開始 |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
| 2026-07-30 | note | TASK-022 で切り替え機能を削除（システム音のみに戻した） |
