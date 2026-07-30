# TASK-022: UI 調整とシャッター音切り替えの削除

- status: in-progress
- priority: high
- started_at: 2026-07-30

## Goal

実機フィードバックによる 3 点の変更。

1. mm ラベルをフレームの上（上辺の外側）に配置する
2. ヘッダーのフィルター名表示をアプリ名（Toruto）にする
3. シャッター音の変更機能を削除する（撮影時はシステムのシャッター音のみ）

## Acceptance Criteria

- [x] mm ラベルが中央フレームの上辺に追従して表示される
- [x] ヘッダーが常に「Toruto」表示になる
- [x] シャッター音の選択メニュー・音源・設定が削除され、撮影時はシステム音が鳴る
- [ ] swiftc 型チェック通過 + 実機確認

## Sub Tasks

- [x] focalLengthLabel を frameOverlay 内に移動（フレーム上辺に追従）
- [x] topBar のタイトルを固定文言に変更、スピーカーメニュー削除
- [x] ShutterSound モデル・音源・SettingsStore.shutterSound・選択 API の削除
- [x] テスト更新

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | 実機フィードバック反映 |
| 2026-07-30 | note | PR #23 を main にマージ完了。swiftc型チェック+実機確認は未確認のためstatusはin-progressのまま据え置き |
