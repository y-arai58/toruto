# TASK-014: カスタムプリセット（複製 + 微調整）

- status: done
- priority: low
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

既存プリセットを複製して主要 4 項目（彩度・色温度・グレイン・ビネット）だけ微調整し、
名前を付けて保存できるようにする。フルエディタは作らない（加工アプリ化を避ける）。

## Acceptance Criteria

- [x] チップの長押しメニューから「複製して調整」でエディタが開く
- [x] エディタはハーフシートで、調整中の値がプレビューへライブ反映される
- [x] 名前を付けて保存するとプリセット一覧に追加され、選択状態になる
- [x] カスタムプリセットは長押しメニューから削除できる（バンドル定義は削除不可）
- [x] カスタムプリセットは再起動後も保持される（UserDefaults）
- [x] ViewModel の単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] Services/CustomPresetStore.swift + UserDefaults 実装
- [x] CameraViewModel の draft 編集フロー（begin / update / save / cancel / delete）
- [x] PresetSelector を contextMenu 化（お気に入り / 複製して調整 / 削除）
- [x] CustomPresetEditorView（ハーフシート + スライダー4本）
- [x] Mock 対応 + テスト

## Notes

- お気に入りのトグルは長押し → contextMenu 内の項目に移動（機能は維持）

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | 方式はユーザー確認済み（複製+微調整） |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
