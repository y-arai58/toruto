# TASK-018: アプリアイコン

- status: in-progress
- priority: medium
- started_at: 2026-07-30

## Goal

ブランドキーワード（Simple / Stylish / Pocket Camera・ダークベース）に沿った
アプリアイコンを作成し、Assets に組み込む。

## Acceptance Criteria

- [x] 1024x1024・不透過の AppIcon が Assets.xcassets に入っている
- [x] モチーフがプロダクト由来である（中央フレーム 3:4 + レンズ + 日付スタンプの橙）
- [x] ホーム画面で視認性がある（ダークベース・細部に頼らない構成）
- [ ] 実機/シミュレータでアイコン表示を確認

## Sub Tasks

- [x] アイコン生成スクリプト（再生成可能にしておく）
- [x] AppIcon.appiconset への組み込み（Contents.json 更新）

## Notes

- 生成スクリプトは Design/ に置き、色・構図の調整後に再実行できるようにする

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | リリース準備として開始 |
