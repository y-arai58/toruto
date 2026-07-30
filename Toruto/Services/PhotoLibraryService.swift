import Foundation

enum PhotoLibraryError: Error {
    case permissionDenied
    case saveFailed
    case loadFailed
}

/// 加工済み画像のフォトライブラリ保存と履歴取得を担う
protocol PhotoLibraryService: AnyObject {
    /// 画像データを保存する。権限が未決定の場合はリクエストする
    func save(_ imageData: Data) async throws
    /// Toruto アルバムの写真データを新しい順に返す
    func loadRecentPhotoData(limit: Int) async throws -> [Data]
}
