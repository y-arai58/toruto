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

    enum SaveError: Equatable {
        case permissionDenied
        case failed
    }

    private(set) var status: Status = .idle
    private(set) var isCapturing = false
    private(set) var lastCapturedImage: UIImage?
    private(set) var presets: [CameraPreset] = []
    private(set) var currentPreset: CameraPreset?
    private(set) var saveError: SaveError?

    private let cameraService: any CameraService
    private let imageProcessor: any ImageProcessor
    private let presetRepository: any PresetRepository
    private let photoLibraryService: any PhotoLibraryService

    init(
        cameraService: (any CameraService)? = nil,
        imageProcessor: (any ImageProcessor)? = nil,
        presetRepository: (any PresetRepository)? = nil,
        photoLibraryService: (any PhotoLibraryService)? = nil
    ) {
        self.cameraService = cameraService ?? DefaultCameraService()
        self.imageProcessor = imageProcessor ?? DefaultImageProcessor()
        self.presetRepository = presetRepository ?? BundlePresetRepository()
        self.photoLibraryService = photoLibraryService ?? DefaultPhotoLibraryService()
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

    /// 撮影 → Crop + フィルター → フォトライブラリ保存まで行う。
    /// 加工済み画像のみを保存し、元画像は残さない
    func capturePhoto() async {
        guard status == .running, !isCapturing else { return }
        isCapturing = true
        saveError = nil
        defer { isCapturing = false }
        do {
            let data = try await cameraService.capturePhoto()
            guard let processed = processCapturedPhoto(data) else {
                saveError = .failed
                return
            }
            lastCapturedImage = UIImage(cgImage: processed.cgImage)
            try await photoLibraryService.save(processed.data)
        } catch PhotoLibraryError.permissionDenied {
            saveError = .permissionDenied
        } catch {
            saveError = .failed
        }
    }

    private func loadPresets() {
        presets = (try? presetRepository.loadPresets()) ?? []
        currentPreset = presets.first
    }

    /// 撮影データにプレビューと同じ Crop + フィルターを適用し、
    /// サムネイル用 CGImage と保存用データを生成する
    private func processCapturedPhoto(_ data: Data) -> (cgImage: CGImage, data: Data)? {
        guard let source = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        let parameters = currentPreset?.filterParameters ?? FilterParameters()
        let processed = imageProcessor.process(source, with: parameters)
        guard let cgImage = imageProcessor.renderCGImage(from: processed),
              let photoData = imageProcessor.makePhotoData(from: processed) else {
            return nil
        }
        return (cgImage, photoData)
    }
}
