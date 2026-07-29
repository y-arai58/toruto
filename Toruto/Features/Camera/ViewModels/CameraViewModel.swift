import CoreImage
import Observation
import UIKit

@MainActor
@Observable
final class CameraViewModel {
    enum Status: Equatable {
        case idle
        case running
        case permissionDenied
        case unavailable
    }

    private(set) var status: Status = .idle
    private(set) var isCapturing = false
    private(set) var lastCapturedImage: UIImage?

    private let cameraService: any CameraService

    init(cameraService: any CameraService = DefaultCameraService()) {
        self.cameraService = cameraService
    }

    func makePreviewStream() -> AsyncStream<CIImage> {
        cameraService.makePreviewStream()
    }

    func startSession() async {
        do {
            try await cameraService.start()
            status = .running
        } catch CameraServiceError.permissionDenied {
            status = .permissionDenied
        } catch {
            status = .unavailable
        }
    }

    func stopSession() async {
        await cameraService.stop()
        if status == .running {
            status = .idle
        }
    }

    func capturePhoto() async {
        guard status == .running, !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }
        do {
            let data = try await cameraService.capturePhoto()
            lastCapturedImage = UIImage(data: data)
        } catch {
            // 保存パイプラインは Phase 1-b。現段階では撮影失敗を UI に出さない
        }
    }
}
