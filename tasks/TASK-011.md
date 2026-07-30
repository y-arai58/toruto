# TASK-011: ランダムカメラ

- status: in-progress
- priority: low
- started_at: 2026-07-30

## Goal

Phase 3 開始。ダイスボタンでプリセットをランダムに選び、
「今日はどのカメラで撮る？」の遊びを 1 タップで提供する。

## Acceptance Criteria

- [x] ダイスアイコンのタップでプリセットがランダムに切り替わる
- [x] 必ず現在と異なるプリセットが選ばれる（1 つしかない場合を除く）
- [x] 切り替え時の Haptics・プレビュー即時反映は既存挙動と同じ
- [x] ViewModel の単体テストがある
- [ ] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] CameraViewModel.selectRandomPreset
- [x] topBar にダイスボタンを追加
- [x] テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 3 開始 |
