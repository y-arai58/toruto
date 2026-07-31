# TASK-019: 前面カメラのプレビューが横向きになる不具合の修正

- status: done
- priority: high
- started_at: 2026-07-30
- completed_at: 2026-07-31

> **この修正自体では直らなかった。** 症状は解消したが、実際の原因と修正は [TASK-024](TASK-024.md) を参照。

## 症状

前面カメラに切り替えると、端末を縦に持っていてもプレビューが横撮影状態になる
（頭の頂点が左を向く）。背面では正常。

## 原因

`reconfigureInput`（前面/背面・レンズ切替時の入力付け替え）で、回転・ミラー設定
（`updateConnections`）を `commitConfiguration` の**前**（defer で commit される前）に
呼んでいた。入力を付け替えた場合、新しい入力と出力の接続は commit 時に確定するため、
その時点では `connection(with: .video)` が新しい接続を返さず、
`videoRotationAngle = 90` が新接続に適用されていなかった。

初回構成（`configureSessionIfNeeded`）は出力追加時に既存入力との接続が
即座に作られるため、問題が顕在化しなかった。

## 修正

- `reconfigureInput` の defer commit をやめ、明示的に commit した**後**に
  `updateConnections()` と露出補正の再適用を行う

## Acceptance Criteria

- [x] 前面カメラのプレビューが縦持ちで正しい向きになる（実機確認、TASK-024 の修正で達成）
- [x] 背面・レンズ切替・ミラー表示の既存動作が変わらない
- [x] swiftc 型チェック通過

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | 実機検証でユーザーが発見 |
| 2026-07-30 | blocked | 実機で症状が変わらず。原因の仮説が誤りだったため TASK-024 で再調査 |
| 2026-07-31 | completed | TASK-024 で根本原因を特定・修正し、実機確認 OK |
