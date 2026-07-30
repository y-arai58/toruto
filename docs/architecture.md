# Architecture

## レイヤー構成

```text
App (SwiftUI エントリポイント)
  │
  ▼
Features/Camera (Views / ViewModels / Components)
  │
  ▼
Services
  ├── CameraService       … AVCaptureSession の管理、プレビュー供給、撮影
  ├── ImageProcessor      … Core Image によるフィルター適用 + 中央フレーム Crop
  └── PhotoLibraryService … PhotoKit による加工済み画像の保存
  │
  ▼
Models (プリセット定義・フィルターパラメータ等のピュアな型)
```

## ディレクトリ構成

```text
Toruto/
├── App/
├── Features/
│   └── Camera/
│       ├── Views/
│       ├── ViewModels/
│       └── Components/
├── Services/
├── Models/
├── Resources/
│   ├── Assets.xcassets
│   └── Filters/
├── Utilities/
└── Tests/
```

## 依存ルール

- 依存は上から下への単方向のみ: View → ViewModel → Services → Models
- Services は SwiftUI に依存しない（UIKit/SwiftUI の import 禁止）
- Models はピュアな型のみ。フレームワーク依存を持たない
- Features 間の直接 import はしない（現状 Camera のみだが将来も同様）

## 撮影パイプライン

```text
AVCaptureSession
  → プレビューフレーム（フィルター適用済みをリアルタイム表示）
  → シャッター
  → ImageProcessor（中央フレーム Crop → フィルター適用）
  → PhotoLibraryService（加工済み画像のみ保存）
```

## 責務の要点

- **CameraService**: セッション起動/停止、権限リクエスト、前面/背面切替、フレーム供給
- **ImageProcessor**: CIFilter チェーンの構築、Crop 領域の計算、CGImage への変換
- **PhotoLibraryService**: 保存権限、PHPhotoLibrary への書き込み

## 技術方針（決定事項）

| 項目 | 決定 |
|---|---|
| 最低対応 OS | iOS 17 |
| 中央フレーム | 3:4 固定・ピンチでサイズ可変（換算 13〜260mm・既定 80%）。プレビューは全画角 + 外側を暗く表示 |
| カメラ切替 | 前面/背面のみ（レンズ切替は MVP 外） |
| プレビュー描画 | MTKView + Metal バックの CIContext |
| 保存形式 | HEIC（非対応環境のみ JPEG フォールバック） |
| メタデータ | 撮影日時・向きは保持、位置情報は付与しない |
