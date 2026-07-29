import Foundation

enum PhotoLibraryError: Error {
    case permissionDenied
    case saveFailed
}

/// 加工済み画像のフォトライブラリ保存を担う
protocol PhotoLibraryService: AnyObject {
    /// 画像データを保存する。権限が未決定の場合はリクエストする
    func save(_ imageData: Data) async throws
}
