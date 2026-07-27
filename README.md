# Toruto

> **簡単に、手軽に、おしゃれなカメラ体験を。**

Torutoは、デジタルカメラやフィルムカメラの「撮る楽しさ」を、iPhoneで手軽に楽しめるカメラアプリです。

写真をあとから加工するのではなく、**撮った瞬間に完成した一枚**を残せることを大切にしています。

---

# コンセプト

誰でも気軽に、好きなカメラを選んで撮影できる。

その日の気分に合わせてカメラを着替えるような、新しい撮影体験を提供します。

## キーワード

- Simple
- Stylish
- Fun
- Everyday
- Pocket Camera
- Digital Camera
- Film Camera

---

# MVP

## 必須機能

### 📷 撮影

- リアルタイムカメラ
- 撮影時点でエフェクト適用
- 加工済み画像を保存

---

### 🖼 フレーム撮影

Dazz Camのように、画面中央のフレーム内だけが写真として保存されます。

ユーザーは完成イメージを確認しながら撮影できます。

---

### 🎞 カメラプリセット

例

- CCD
- Digital Compact
- Disposable Camera
- Flash
- Soft
- Vintage

プリセットを切り替えるだけで撮影体験が変わります。

---

# 技術スタック

|項目|内容|
|---|---|
|Language|Swift|
|UI|SwiftUI|
|Camera|AVFoundation|
|Image Processing|Core Image|
|Photo Library|PhotoKit|

---

# アーキテクチャ

```text
Toruto
│
├── App
│
├── Features
│   └── Camera
│
├── Services
│   ├── CameraService
│   ├── ImageProcessor
│   └── PhotoLibraryService
│
├── Models
│
├── Resources
│
└── Utilities
```

---

# ディレクトリ構成

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

---

# 今後追加予定

- カメラ追加（CCD / Film / Compact）
- フラッシュエフェクト
- 日付スタンプ
- シャッター音切り替え
- レンズ切り替え
- ランダムカメラ
- お気に入り登録
- 撮影履歴

---

# 開発方針

- **撮影体験を最優先する**
- 設定よりも「すぐ撮れる」ことを重視する
- UIはシンプルで直感的に
- 加工アプリではなく「カメラアプリ」として設計する

---

# ブランド

**Toruto** は、「簡単に、おしゃれなカメラを持ち歩く」という体験を表現するブランドです。

スマートフォンをただのカメラではなく、その日の気分に合わせて選べる**ポケットカメラ**へと変えることを目指しています。

---

## 開発ロードマップ

### Phase 1（MVP）
- カメラ撮影
- フレーム撮影
- 加工済み保存
- カメラプリセット切り替え

### Phase 2
- カメララインナップ追加
- 撮影パラメータの調整
- お気に入り機能

### Phase 3
- 新しいカメラパックの追加
- カスタムプリセット
- iCloud同期（検討）

---

## ライセンス

Private Repository

---

## ブランドについて

**Toruto** の名前は、「撮る」を直接説明するためではなく、**「撮ることがもっと楽しくなる体験」**を表現するブランドとして採用しています。
