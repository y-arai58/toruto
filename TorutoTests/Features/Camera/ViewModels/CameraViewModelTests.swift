import Testing
import UIKit
@testable import Toruto

@MainActor
struct CameraViewModelTests {
    @Test
    func startSession_成功時はrunningになる() async {
        let service = MockCameraService()
        let viewModel = CameraViewModel(cameraService: service)

        await viewModel.startSession()

        #expect(viewModel.status == .running)
        #expect(service.startCallCount == 1)
    }

    @Test
    func startSession_権限拒否時はpermissionDeniedになる() async {
        let service = MockCameraService()
        service.startError = CameraServiceError.permissionDenied
        let viewModel = CameraViewModel(cameraService: service)

        await viewModel.startSession()

        #expect(viewModel.status == .permissionDenied)
    }

    @Test
    func startSession_デバイス不可時はunavailableになる() async {
        let service = MockCameraService()
        service.startError = CameraServiceError.deviceUnavailable
        let viewModel = CameraViewModel(cameraService: service)

        await viewModel.startSession()

        #expect(viewModel.status == .unavailable)
    }

    @Test
    func stopSession_実行中に停止するとidleに戻る() async {
        let service = MockCameraService()
        let viewModel = CameraViewModel(cameraService: service)
        await viewModel.startSession()

        await viewModel.stopSession()

        #expect(viewModel.status == .idle)
        #expect(service.stopCallCount == 1)
    }

    @Test
    func capturePhoto_成功時は画像を保持する() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let viewModel = CameraViewModel(cameraService: service)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(viewModel.lastCapturedImage != nil)
        #expect(service.captureCallCount == 1)
        #expect(viewModel.isCapturing == false)
    }

    @Test
    func capturePhoto_起動前は撮影しない() async {
        let service = MockCameraService()
        let viewModel = CameraViewModel(cameraService: service)

        await viewModel.capturePhoto()

        #expect(service.captureCallCount == 0)
        #expect(viewModel.lastCapturedImage == nil)
    }

    @Test
    func capturePhoto_失敗時は画像を保持しない() async {
        let service = MockCameraService()
        service.captureResult = .failure(CameraServiceError.captureFailed)
        let viewModel = CameraViewModel(cameraService: service)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(viewModel.lastCapturedImage == nil)
        #expect(viewModel.isCapturing == false)
    }

    private static func makeImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.pngData { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
