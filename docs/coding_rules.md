# Coding Rules

## 基本原則

- シンプルさ第一。すべての変更をできるだけシンプルに
- 根本原因を直す。一時的な修正はしない
- 変更は必要な部分だけ（最小限の影響）

## Swift

- Swift 最新安定版。強制アンラップ（`!`）は原則禁止
- `enum` + `CaseIterable` でプリセット等の有限集合を表現
- 値型（struct）優先。参照型は Service など状態を持つものに限定
- 命名: 型は PascalCase、プロパティ/関数は camelCase、ファイル名は型名と一致

## SwiftUI

- View は小さく分割し、`Features/Camera/Components/` に切り出す
- 状態管理: ViewModel は `@Observable` で統一（最低対応が iOS 17 のため）
- View にビジネスロジックを書かない。ViewModel → Service に委譲する
- プレビュー（#Preview）を各 View に用意する

## Services

- protocol でインターフェースを定義し、ViewModel は protocol に依存する
  （テスト時にモック差し替え可能にするため）
- SwiftUI / UIKit を import しない
- カメラ・保存の権限処理は各 Service 内に閉じる

## 並行処理

- Swift Concurrency（async/await）を使用。completion handler は書かない
- AVCaptureSession の操作は専用の DispatchQueue / actor 上で行う
- UI 更新は `@MainActor`

## エラー処理

- 独自 Error 型（enum）を定義し、ユーザー向けメッセージへ変換する層を分ける
- 権限拒否・デバイス不可はクラッシュさせず UI で案内する

## テスト

- ImageProcessor（Crop 計算・フィルターチェーン）は単体テスト必須
- ViewModel はモック Service を注入してテスト
- テストは `Tests/` に、対象と対応するディレクトリ構成で配置

## Git

- Branch: `{type}/TASK-XXX-{short-desc}`（feature/ fix/ refactor/ docs/ chore/）
- Commit: `{type}(TASK-XXX): {description}` 日本語・現在形・72文字以内
- PR は Squash and Merge。UI 変更はスクリーンショット添付
