# TASK-016: レンズ切り替え（0.5x / 1x / 2x）

- status: in-progress
- priority: low
- started_at: 2026-07-30

## Goal

背面カメラのレンズ（超広角 / 広角 / 望遠）を切り替えられるようにする。
デバイスに搭載されているレンズだけをボタン表示する。

## Acceptance Criteria

- [x] プレビュー下部のボタンで 0.5x / 1x / 2x を切り替えられる（搭載レンズのみ表示）
- [x] レンズが 1 つしかない場合はボタン自体を表示しない
- [x] 前面カメラではレンズ切替を表示しない。背面に戻すと 1x にリセットされる
- [x] 切替後も露出補正が維持される
- [x] ViewModel の単体テストがある
- [ ] swiftc 型チェック通過 + ユーザー環境（実機）で動作確認

## Sub Tasks

- [x] Models/CameraLens.swift
- [x] CameraService.availableLenses / selectLens + DefaultCameraService 実装
- [x] CameraViewModel のレンズ状態管理
- [x] プレビュー下部のレンズボタン UI
- [x] Mock 対応 + テスト

## Notes

- 実レンズの切替はシミュレータで確認できないため、実機検証が必須

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 3 として開始 |
