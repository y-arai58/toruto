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
    private(set) var presets: [CameraPreset] = []
    private(set) var currentPreset: CameraPreset?

    private let cameraService: any CameraService
    private let imageProcessor: any ImageProcessor
    private let presetRepository: any PresetRepository

    init(
        cameraService: (any CameraService)? = nil,
        imageProcessor: (any ImageProcessor)? = nil,
        presetRepository: (any PresetRepository)? = nil
    ) {
        self.cameraService = cameraService ?? DefaultCameraService()
        self.imageProcessor = imageProcessor ?? DefaultImageProcessor()
        self.presetRepository = presetRepository ?? BundlePresetRepository()
        loadPresets()
    }

    /// Crop + フィルター適用済みのプレビューフレームを供給する。
    /// パラメータはストリーム生成時に固定される（プリセット切替は TASK-004 で再購読対応）
    func makePreviewStream() -> AsyncStream<CIImage> {
        let source = cameraService.makePreviewStream()
        let processor = imageProcessor
        let parameters = currentPreset?.filterParameters ?? FilterParameters()
        return AsyncStream { continuation in
            let task = Task.detached {
                for await frame in source {
                    continuation.yield(processor.process(frame, with: parameters))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
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
            lastCapturedImage = processCapturedPhoto(data)
        } catch {
            // 保存パイプラインは TASK-003。現段階では撮影失敗を UI に出さない
        }
    }

    private func loadPresets() {
        presets = (try? presetRepository.loadPresets()) ?? []
        currentPreset = presets.first
    }

    /// 撮影データにプレビューと同じ Crop + フィルターを適用する
    private func processCapturedPhoto(_ data: Data) -> UIImage? {
        guard let source = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            return UIImage(data: data)
        }
        let parameters = currentPreset?.filterParameters ?? FilterParameters()
        let processed = imageProcessor.process(source, with: parameters)
        guard let cgImage = imageProcessor.renderCGImage(from: processed) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
