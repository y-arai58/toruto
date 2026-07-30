import Foundation
@testable import Toruto

final class MockPhotoLibraryService: PhotoLibraryService {
    var saveError: Error?
    var loadResult: Result<[Data], Error> = .success([])
    private(set) var savedData: [Data] = []
    private(set) var lastLoadLimit: Int?

    func save(_ imageData: Data) async throws {
        if let saveError {
            throw saveError
        }
        savedData.append(imageData)
    }

    func loadRecentPhotoData(limit: Int) async throws -> [Data] {
        lastLoadLimit = limit
        return try loadResult.get()
    }
}
