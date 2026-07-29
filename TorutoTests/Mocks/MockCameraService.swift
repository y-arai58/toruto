import CoreImage
import Foundation
@testable import Toruto

final class MockCameraService: CameraService {
    var authorizationGranted = true
    var startError: Error?
    var captureResult: Result<Data, Error> = .failure(CameraServiceError.captureFailed)

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var captureCallCount = 0

    func makePreviewStream() -> AsyncStream<CIImage> {
        AsyncStream { $0.finish() }
    }

    func requestAuthorization() async -> Bool {
        authorizationGranted
    }

    func start() async throws {
        startCallCount += 1
        if let startError {
            throw startError
        }
    }

    func stop() async {
        stopCallCount += 1
    }

    func capturePhoto() async throws -> Data {
        captureCallCount += 1
        return try captureResult.get()
    }
}
