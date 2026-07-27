# Camera Presets

## コンセプト

プリセット = 「カメラ本体」。切り替えるだけで撮影体験が変わる。
その日の気分でカメラを着替える体験の中核。

## MVP ラインナップ（例）

| プリセット | イメージ | 特徴 |
|---|---|---|
| CCD | 2000年代デジカメ | 高彩度・ややシアン寄り・軽い滲み |
| Digital Compact | コンデジ | ニュートラル・シャープ・軽いビネット |
| Disposable Camera | 写ルンです | 粒子・色転び・強めの周辺減光 |
| Flash | フラッシュ撮影 | ハイコントラスト・ハレーション |
| Soft | ソフトフォーカス | 低コントラスト・にじみ・淡い色 |
| Vintage | フィルム | 褪色・グレイン・暖色寄り |

## プリセットが持つ要素

- フィルターチェーン定義（[filters.md](filters.md) 参照）
- 表示名・サムネイル
- （将来）シャッター音・日付スタンプ有無
  ※ フレーム比率は 3:4 固定でプリセットには含めない

## データ構造（方針）

```swift
struct CameraPreset: Identifiable {
    let id: String            // "ccd", "vintage" など
    let displayName: String
    let filterParameters: FilterParameters  // Models/ のピュアな型
}
```

- 定義は `Resources/Filters/` に置き、追加時のコード変更を最小にする
- プリセットの列挙・選択状態は ViewModel が管理する

## 拡張予定（Phase 2〜3）

- カメラ追加（CCD / Film / Compact のバリエーション）
- お気に入り登録
- ランダムカメラ
- カスタムプリセット
- カメラパック（テーマ別セット販売の可能性）
