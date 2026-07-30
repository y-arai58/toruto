# TASK-024: 前面カメラの向き補正を接続まかせにするのをやめる

- status: in-progress
- priority: critical
- started_at: 2026-07-30

## 症状

TASK-019 の修正後も、前面カメラに切り替えると縦持ちでプレビューが横向き（頭の頂点が左）
になる。TASK-019 の前とまったく同じ見え方で、**保存された写真も同じく横向き**。
背面は正常。

## 原因

`updateConnections()` で `AVCaptureConnection` に回転・ミラーを設定していたが、
前面カメラでは `videoOutput` / `photoOutput` の**両方**に適用されていなかった。

```swift
for connection in [videoOutput.connection(with: .video), photoOutput.connection(with: .video)] {
    guard let connection else { continue }              // nil なら黙って無視
    if connection.isVideoRotationAngleSupported(90) {   // false なら黙って無視
        connection.videoRotationAngle = 90
    }
```

`guard let` と `if` が**どちらも失敗を握りつぶす**構造になっていて、
入力を張り替えた直後に接続が取得できない/回転角が非対応でも、
エラーも警告もなく回転だけが抜け落ちる。

TASK-019 では「設定するタイミング（commit の前か後か）」が原因だと考えて
`commitConfiguration()` の後に移したが、症状が一切変わらなかったことから、
タイミングではなく**接続への設定そのものが届いていない**と判断した。

背面が正常なのは、初回構成では出力追加時に既存入力との接続が即座に作られるため。

## 修正

タイミングを調整して接続に設定が届くのを期待するのをやめ、
**向きの補正をコード側の一箇所に集約する**。

- `CameraOrientation.portrait(for:)` を追加（背面 `.right` / 前面 `.leftMirrored`）
- プレビュー: `captureOutput` で `CIImage.oriented(_:)` を適用
- 撮影: `CapturedPhoto` に向きを載せて返し、ViewModel で `oriented(_:)` を適用
  （EXIF に頼らないため `applyOrientationProperty: false`）
- 接続側の回転・ミラーは `resetConnectionTransforms()` で無効に固定。
  この設定が届かなくても既定値と同じなので表示向きは壊れない

これで向きは AVFoundation の挙動に依存せず、コードだけで決まる。

## Acceptance Criteria

- [x] 向きの定義が 1 箇所（`CameraOrientation`）に集約されている
- [x] プレビューと保存画像が同じ向き定義を使う
- [x] 接続への設定が失敗しても表示向きが壊れない構造になっている
- [x] `CameraOrientation` と撮影データへの向き適用の単体テストを追加
- [x] swiftc 型チェック通過（アプリターゲット）
- [ ] 実機で前面カメラのプレビューが縦持ちで正しい向きになる
- [ ] 実機で前面カメラの保存写真が正しい向き・鏡像になる
- [ ] 実機で背面・レンズ切替の既存動作が変わらない

## 実機で向きがずれていた場合の直し方

`Toruto/Utilities/CameraOrientation.swift` の 1 行を入れ替える。

| 見え方 | 直し方 |
|---|---|
| 前面が上下逆さま | `.leftMirrored` → `.rightMirrored` |
| 前面が鏡像でない（文字が読める） | `.leftMirrored` → `.right` |
| 背面が横向きになった | `.right` → `.left` |

## Sub Tasks

- [x] `CameraOrientation` を追加
- [x] `CapturedPhoto`（データ + 向き）を追加し `CameraService.capturePhoto` の戻り値を変更
- [x] `DefaultCameraService`: `updateConnections` を `updateOrientation` + `resetConnectionTransforms` に置き換え
- [x] `captureOutput` で `oriented(_:)` を適用
- [x] `CameraViewModel.processCapturedPhoto` で `oriented(_:)` を適用
- [x] `MockCameraService` / `MockImageProcessor` を更新
- [x] `CameraOrientationTests` と撮影データの向き補正テストを追加
- [x] `Design/typecheck.sh`（サンドボックスでの型チェック手段）を追加

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | TASK-019 の修正では直らなかったため原因を再調査 |
| 2026-07-30 | note | サンドボックスから xcodebuild が使えないため、テスト実行は未実施（型チェックのみ） |
