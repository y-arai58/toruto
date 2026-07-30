import Foundation
import Photos

/// PhotoKit による PhotoLibraryService の標準実装。
/// readWrite 権限が取れれば「Toruto」アルバムへ保存し、
/// addOnly のみの場合はカメラロールへの保存にフォールバックする。位置情報は付与しない。
final class DefaultPhotoLibraryService: PhotoLibraryService {
    private static let albumName = "Toruto"

    func save(_ imageData: Data) async throws {
        if await requestAuthorization(for: .readWrite) {
            let album = try? await ensureAlbum()
            try await performSave(imageData, into: album)
            return
        }
        // readWrite が拒否されても addOnly が許可されていれば保存自体は続ける
        guard await requestAuthorization(for: .addOnly) else {
            throw PhotoLibraryError.permissionDenied
        }
        try await performSave(imageData, into: nil)
    }

    func loadRecentPhotoData(limit: Int) async throws -> [Data] {
        guard await requestAuthorization(for: .readWrite) else {
            throw PhotoLibraryError.permissionDenied
        }
        guard let album = fetchAlbum() else {
            return []
        }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit
        let assets = PHAsset.fetchAssets(in: album, options: options)

        var results: [Data] = []
        for index in 0..<assets.count {
            if let data = await requestImageData(for: assets.object(at: index)) {
                results.append(data)
            }
        }
        return results
    }

    private func performSave(_ imageData: Data, into album: PHAssetCollection?) async throws {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
                request.creationDate = Date()
                if let album,
                   let placeholder = request.placeholderForCreatedAsset,
                   let change = PHAssetCollectionChangeRequest(for: album) {
                    change.addAssets([placeholder] as NSArray)
                }
            }
        } catch {
            throw PhotoLibraryError.saveFailed
        }
    }

    private func fetchAlbum() -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", Self.albumName)
        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: options
        ).firstObject
    }

    private func ensureAlbum() async throws -> PHAssetCollection {
        if let album = fetchAlbum() {
            return album
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumName)
            }
        } catch {
            throw PhotoLibraryError.saveFailed
        }
        guard let album = fetchAlbum() else {
            throw PhotoLibraryError.saveFailed
        }
        return album
    }

    private func requestImageData(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }

    private func requestAuthorization(for accessLevel: PHAccessLevel) async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: accessLevel) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: accessLevel)
            return status == .authorized || status == .limited
        default:
            return false
        }
    }
}
