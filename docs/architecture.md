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
