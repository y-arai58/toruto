# iCloud 同期（検討メモ）

Phase 3「iCloud 同期（検討）」の調査結果。**結論: MVP 後に NSUbiquitousKeyValueStore で最小同期から始めるのが妥当**。

## 同期する価値があるデータ

| データ | 現在の保存先 | サイズ | 同期価値 |
|---|---|---|---|
| お気に入りプリセット ID | UserDefaults | 数百 B | 高（機種変更で消えると体験が悪い） |
| カスタムプリセット | UserDefaults (JSON) | 数 KB | 高（ユーザーの作成物） |
| 撮影設定（日付スタンプ・シャッター音） | UserDefaults | 数十 B | 中 |
| 写真本体 | フォトライブラリ | - | 不要（iCloud フォトが担う領域） |

## 実現方式の比較

| 方式 | 向き | コスト | 備考 |
|---|---|---|---|
| NSUbiquitousKeyValueStore | 小さな設定値 | 実装小 | 合計 1MB / 1024 キー上限。上記データは全部収まる |
| CloudKit (CKRecord) | 構造化データ | 実装中〜大 | カスタムプリセットが大量になる将来には有効 |
| CoreData + CloudKit ミラーリング | ローカル DB がある場合 | 実装大 | 現状 DB なしのため過剰 |

## 推奨プラン

1. **Step 1（小）**: FavoriteStore / SettingsStore / CustomPresetStore の保存先を
   UserDefaults + NSUbiquitousKeyValueStore の二重書き込みにする
   （protocol は変更不要。実装クラスの差し替えだけで済む現構造を活かす）
2. **Step 2（将来）**: カスタムプリセットの共有・配布をやるなら CloudKit へ移行

## 留意点

- iCloud capability（entitlements）の追加が必要 → Apple Developer アカウント設定と合わせて実施
- KVS は「最後の書き込みが勝つ」。複数端末での同時編集は稀と割り切る
- 同期タイミングは didChangeExternallyNotification で受けて Store → ViewModel へ反映
- ユーザーへの見せ方: 設定 UI は作らず、サイレント同期（Toruto の「設定より撮影」方針に従う）

## 判断

- MVP リリース時点では**実装しない**（オフラインで完結しており困らない）
- 機種変更サポートの要望が出た時点で Step 1 を TASK 化する
