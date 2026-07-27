# Filters

## 方針

- フィルターは Core Image（CIFilter チェーン）で実装する
- **撮影時に適用**する。後から編集・解除はできない（加工済み画像のみ保存）
- プレビューにも同じフィルターをリアルタイム適用し、完成イメージを見ながら撮影できるようにする

## パイプライン

```text
入力フレーム (CVPixelBuffer)
  → CIImage
  → 中央フレーム Crop
  → CIFilter チェーン（プリセットごとに定義）
  → 出力（プレビュー表示 / 保存用 CGImage）
```

## フィルター構成要素（例）

| 要素 | Core Image フィルター例 | 用途 |
|---|---|---|
| 色調 | CIColorControls / CIToneCurve | 彩度・コントラスト・明るさ |
| 色被り | CIColorMatrix / CITemperatureAndTint | フィルム風の色転び |
| 粒子 | CIRandomGenerator 合成 | フィルムグレイン |
| 周辺減光 | CIVignette | レンズ感 |
| にじみ | CIGaussianBlur（弱） | ソフトフォーカス |
| ハレーション | CIBloom | フラッシュ・光の滲み |

## 定義の置き場所

- フィルターパラメータは `Resources/Filters/` に定義（プリセット単位）
- コード側は `Models/` のプリセット型がパラメータを持ち、
  `ImageProcessor` がそれを CIFilter チェーンへ変換する
- フィルター追加時にコード変更が最小になる構造にする

## パフォーマンス指針

- プレビューは 30fps を維持できる範囲でフィルターを構成する
- CIContext は使い回す（毎フレーム生成しない）
- 保存時のみフル解像度で処理し、プレビューは表示解像度で処理する

## 決定事項

- **プレビュー描画方式**: MTKView + Metal バックの CIContext
  （SwiftUI からは UIViewRepresentable でラップ。30fps 維持を優先）
- **保存形式**: HEIC（非対応環境のみ JPEG フォールバック）
- **EXIF**: 撮影日時・画像の向きは保持。位置情報は付与しない
