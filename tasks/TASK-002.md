# TASK-002: ImageProcessor（中央フレーム Crop + フィルター適用）

- status: done
- priority: high
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

Phase 1-b 前半。プレビューと撮影画像に「中央フレーム 3:4 Crop → CIFilter チェーン」を適用する。
保存（PhotoLibraryService）は TASK-003、プリセット切替 UI は TASK-004。

## Acceptance Criteria

- [x] Models に FilterParameters / CameraPreset（ピュアな Codable 型）がある
- [x] Resources/Filters/ にプリセット定義（JSON）があり、コード変更なしにパラメータ調整できる
- [x] ImageProcessor が中央 3:4 Crop + フィルターチェーンを適用する（CIContext は使い回す）
- [x] プレビューにフィルター適用済みフレームがリアルタイム表示される
- [x] 撮影画像にも同じ Crop + フィルターが適用される
- [x] Crop 計算・パラメータデコード・フィルターチェーンの単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] Models/FilterParameters.swift + Models/CameraPreset.swift
- [x] Resources/Filters/presets.json（MVP 6 プリセット）
- [x] Utilities/CropCalculator.swift（中央 3:4 Crop 計算）
- [x] Services/ImageProcessor.swift + DefaultImageProcessor
- [x] Services/PresetRepository.swift（Bundle から JSON 読み込み）
- [x] CameraViewModel / 撮影パスへの組み込み
- [x] 単体テスト（CropCalculator / FilterParameters / ImageProcessor / PresetRepository）

## Notes

- プレビューのフィルターパラメータはストリーム生成時に固定される。
  プリセット切替時の再購読は TASK-004 で対応する

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | Phase 1-b 前半として開始 |
| 2026-07-30 | started | Models / ImageProcessor から着手 |
| 2026-07-30 | completed | ユーザー環境でテスト21件通過を確認 |
