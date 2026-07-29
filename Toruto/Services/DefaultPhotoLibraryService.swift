import Foundation
import Photos

/// PhotoKit による PhotoLibraryService の標準実装。
/// 追加のみの権限（addOnly）を使い、位置情報は付与しない。
final class DefaultPhotoLibraryService: PhotoLibraryService {
    func save(_ imageData: Data) async throws {
        guard await requestAddAuthorization() else {
            throw PhotoLibraryError.permissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
                request.creationDate = Date()
            }
        } catch {
            throw PhotoLibraryError.saveFailed
        }
    }

    private func requestAddAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited
        default:
            return false
        }
    }
}
