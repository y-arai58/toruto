# TASK-008: お気に入り登録

- status: in-progress
- priority: medium
- started_at: 2026-07-30

## Goal

プリセットをお気に入り登録できるようにし、選択 UI でお気に入りを先頭に表示する。

## Acceptance Criteria

- [x] チップの長押しでお気に入りをトグルできる（Haptics 付き）
- [x] お気に入りは星マークで表示され、一覧の先頭に並ぶ（それ以外は定義順を維持）
- [x] お気に入りはアプリ再起動後も保持される（UserDefaults）
- [x] ViewModel の単体テストがある
- [ ] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] Services/FavoriteStore.swift + UserDefaultsFavoriteStore
- [x] CameraViewModel.toggleFavorite + お気に入り優先ソート
- [x] PresetSelector の星マーク + 長押しジェスチャ
- [x] MockFavoriteStore + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 2 として開始 |
