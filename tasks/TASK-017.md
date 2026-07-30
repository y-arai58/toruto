# TASK-017: iCloud 同期の検討

- status: done
- priority: low
- started_at: 2026-07-30
- completed_at: 2026-07-30

## Goal

Phase 3「iCloud 同期（検討）」。実装はせず、同期対象・方式・コストを整理して
判断できる状態の調査メモを残す。

## Acceptance Criteria

- [x] docs/icloud_sync.md に同期対象データの棚卸しがある
- [x] KVS / CloudKit / CoreData ミラーリングの比較と推奨案がある
- [x] MVP 時点で実装しない判断と、再開の条件が明記されている

## Progress Log

| Date | Action | Note |
|---|---|---|
| 2026-07-30 | created | 調査メモ作成 |
| 2026-07-30 | completed | 結論: MVP 後に KVS 二重書き込みで最小同期 |
