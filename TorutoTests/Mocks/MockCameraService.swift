import CoreImage
import Foundation
@testable import Toruto

final class MockCameraService: CameraService {
    var authorizationGranted = true
    var startError: Error?
    var switchCameraError: Error?
    private(set) var lastExposureBias: Float?
    private(set) var lastFlashEnabled: Bool?
    var captureResult: Result<Data, Error> = .failure(CameraServiceError.captureFailed)

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var captureCallCount = 0
    private(set) var switchCameraCallCount = 0

    private var previewContinuation: AsyncStream<CIImage>.Continuation?

    func makePreviewStream() -> AsyncStream<CIImage> {
        AsyncStream { previewContinuation = $0 }
    }

    /// テストからプレビューフレームを流し込む
    func emitPreviewFrame(_ image: CIImage) {
        previewContinuation?.yield(image)
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

    func switchCamera() async throws {
        switchCameraCallCount += 1
        if let switchCameraError {
            throw switchCameraError
        }
    }

    func setExposureBias(_ bias: Float) async throws {
        lastExposureBias = bias
    }

    func setFlashEnabled(_ isEnabled: Bool) async {
        lastFlashEnabled = isEnabled
    }

    func capturePhoto() async throws -> Data {
        captureCallCount += 1
        return try captureResult.get()
    }
}
