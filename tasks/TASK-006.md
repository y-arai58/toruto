# TASK-006: カメラ追加（CCD / Film / Compact バリエーション）

- status: done
- priority: medium
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

Phase 2 開始。プリセットのラインナップを 6 → 9 に拡充する。
TASK-002 で作った「JSON 追加だけで増やせる」構造の実証も兼ねる。

## Acceptance Criteria

- [x] CCD / Film / Compact 系のバリエーションが 3 つ追加されている（計 9）
- [x] コード変更は不要（presets.json とテストの期待値のみ）
- [x] 既存プリセットと重複しない画作りになっている
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] presets.json に ccd_vivid / film / compact_retro を追加
- [x] BundlePresetRepositoryTests の期待値更新

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 2 開始 |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
