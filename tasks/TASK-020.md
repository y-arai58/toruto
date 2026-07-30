# TASK-020: Dazz 方式の中央フレーム表示

- status: in-progress
- priority: high
- started_at: 2026-07-30

## Goal

プレビューを全画角にし、中央フレーム（保存される領域）の外側を暗く表示して
「フレームで切り取って撮る」体験を UI ガイドラインどおりにする。

## 背景

- センサーは 4:3（縦持ちで 3:4）のため、従来の「3:4 中央 Crop」は実質全面で
  何も切り取っていなかった（TASK-020 で発覚）
- 保存フレームを視野の 80% に定義し直し、プレビューでは全画角 + 外側を暗く表示する

## Acceptance Criteria

- [x] プレビューが全画角表示になり、中央フレームの外側が暗く表示される
- [x] 保存される画像は中央フレーム内（視野の 80%・3:4）だけになる
- [x] プレビューのフィルターは全画角に適用される（外側でも画作りを確認できる）
- [x] フレーム定義（比率・スケール）が 1 箇所（Utilities/CameraFrame）に集約されている
- [x] Crop 計算・ImageProcessor のテストが新仕様で更新されている
- [ ] swiftc 型チェック通過 + 実機で「見えている範囲＞保存される範囲」を確認

## Sub Tasks

- [x] Utilities/CameraFrame.swift（aspectRatio 3:4 / scale 0.8）
- [x] CropCalculator に scale 対応
- [x] ImageProcessor.applyFilters（Crop なし・プレビュー用）を追加
- [x] CameraViewModel のプレビューを applyFilters に変更
- [x] CameraView にフレーム外の暗幕オーバーレイ
- [x] docs（architecture / filters / ui_guideline との整合）更新
- [x] テスト更新

## Notes

- プレビューのビネット等は全画角基準になるため、保存画像とはフレーム周辺で
  わずかに見えが異なる（暗幕の下なのでほぼ気づかない想定）

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | ユーザー選択（Dazz 方式）を受けて開始 |
