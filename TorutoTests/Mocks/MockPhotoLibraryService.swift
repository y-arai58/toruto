import Foundation
@testable import Toruto

final class MockPhotoLibraryService: PhotoLibraryService {
    var saveError: Error?
    private(set) var savedData: [Data] = []

    func save(_ imageData: Data) async throws {
        if let saveError {
            throw saveError
        }
        savedData.append(imageData)
    }
}
