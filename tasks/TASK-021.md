# TASK-021: ピンチによる中央フレームのサイズ変更（換算 13〜260mm）

- status: in-progress
- priority: high
- started_at: 2026-07-30

## Goal

Dazz Cam と同様に、ピンチイン/アウトで中央フレーム（保存範囲）のサイズを変更できる
ようにする。中央固定・3:4 固定は変えない（フレーム可変方式・ユーザー選択済み）。

フレームサイズは換算焦点距離として表示する:
- 換算 mm = レンズ基準 mm ÷ フレームスケール（クロップ率）
- レンズ基準: 超広角 = 13mm（0.5x）/ 広角 = 26mm（1x）/ 望遠 = 52mm（2x）
- 上限 260mm（レンズごとにスケール下限 = 基準mm/260）
- レンズボタンは mm プリセット化（タップで該当レンズ + フレーム 100% = 基準 mm）

## Acceptance Criteria

- [x] ピンチでフレームサイズが変わり、換算 mm が表示される（上限 260mm）
- [x] フレームの暗幕・枠線がピンチに追従する
- [x] 保存画像は変更後のフレーム範囲で切り出される
- [x] レンズボタンが 13mm / 26mm / 52mm 表示になり、タップでその画角にリセットされる
- [x] フレームスケールはアプリ再起動後も保持される（UserDefaults）
- [x] ViewModel / ImageProcessor のテストがある
- [ ] swiftc 型チェック通過 + 実機確認

## Sub Tasks

- [x] CameraFrame（defaultScale / maxEquivalentFocalLength / レンズ別 scaleRange）
- [x] CameraLens に equivalentFocalLength、表示名を mm 化
- [x] ImageProcessor.process に frameScale を追加
- [x] SettingsStore に frameScale を追加
- [x] CameraViewModel（setFrameScale / commitFrameScale / displayFocalLength / 撮影パス反映）
- [x] CameraView に MagnifyGesture + mm 表示
- [x] Mock / テスト更新

## Notes

- 換算 mm は物理的に「mm = 基準 mm ÷ クロップ率」なので、基準 mm ちょうど
  （プリセットタップ直後）はフレーム = 全画角となり暗幕が見えない。
  常時暗幕を見せたい場合はズーム方式（videoZoomFactor）への変更が必要（将来検討）
- フレーム極小時（260mm 相当 = 視野の 10〜20%）は保存解像度が大きく下がる

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | ユーザー要望（Dazz 同等のピンチ変更） |
| 2026-07-30 | note | 方式確定: フレーム可変 + mm 換算（13mm=0.5x / 26mm=1x、上限 260mm） |
