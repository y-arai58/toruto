# TASK-013: 撮影履歴（アルバム参照方式）

- status: done
- priority: low
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

保存先を「Toruto」アルバムにし、そのアルバムの中身をアプリ内の履歴として一覧表示する。
アプリ内 DB は持たず、フォトライブラリを唯一の保存場所とする。

## Acceptance Criteria

- [x] 撮影した写真が「Toruto」アルバムに保存される（アルバムは自動作成）
- [x] readWrite 権限が取れない場合は従来どおりカメラロールへ保存される（保存は失敗させない）
- [x] サムネイル/フォトアイコンのタップで履歴シートが開き、アルバムの写真が新しい順に並ぶ
- [x] 読み取り権限拒否時はシート内に設定導線を表示する
- [x] HistoryViewModel の単体テストがある
- [x] swiftc 型チェック通過 + ユーザー環境でテスト通過

## Sub Tasks

- [x] PhotoLibraryService に Toruto アルバムへの保存と履歴取得を追加
- [x] Info.plist に NSPhotoLibraryUsageDescription を追加
- [x] HistoryViewModel + HistoryView（グリッドシート）
- [x] bottomBar のサムネイル枠を履歴入口に変更
- [x] Mock 対応 + テスト

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | 方式はユーザー確認済み（アルバム参照） |
| 2026-07-30 | completed | ユーザー環境でテスト通過・PR マージ済み |
