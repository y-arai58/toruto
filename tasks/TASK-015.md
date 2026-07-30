# TASK-015: 新しいカメラパックの追加

- status: in-progress
- priority: low
- started_at: 2026-07-30

## Goal

プリセット定義をパック構造（presets.json = パックの配列）にし、
新パック「Mono Pack」（モノクロ 3 種）を追加する。
パック追加が JSON 編集だけで済む構造にする。

## Acceptance Criteria

- [x] presets.json がパック構造になり、既存 9 プリセットは Essentials パックに属する
- [x] Mono Pack（Mono / Mono Hard / Mono Film）が追加されている
- [x] 一覧表示・お気に入り・カスタム複製など既存機能がそのまま動く
- [x] Repository / ViewModel の単体テストがある
- [ ] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] Models/CameraPresetPack.swift
- [x] presets.json のパック構造化 + Mono Pack 追加
- [x] PresetRepository.loadPacks + ViewModel のフラット化
- [x] Mock / テスト更新

## Notes

- UI 上のパック見出し表示は将来課題（現状はフラットなチップ列のまま）

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 3 として開始 |
