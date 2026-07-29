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

    static let exposureRange: ClosedRange<Double> = -2...2

    private(set) var status: Status = .idle
    private(set) var isCapturing = false
    private(set) var isSwitchingCamera = false
    private(set) var exposureBias: Double = 0
    private(set) var isFlashEnabled = false
    private(set) var isDateStampEnabled = false
    private(set) var lastCapturedImage: UIImage?
    /// 表示順のプリセット一覧（お気に入りが先頭、それ以外は定義順）
    private(set) var presets: [CameraPreset] = []
    private(set) var currentPreset: CameraPreset?
    private(set) var favoritePresetIDs: Set<String> = []
    private(set) var saveError: SaveError?

    private let cameraService: any CameraService
    private let imageProcessor: any ImageProcessor
    private let presetRepository: any PresetRepository
    private let photoLibraryService: any PhotoLibraryService
    private let favoriteStore: any FavoriteStore
    private let settingsStore: any SettingsStore
    /// presets.json の定義順
    private var orderedPresets: [CameraPreset] = []
    /// プレビュー処理タスク（非 MainActor）と共有するフィルターパラメータ
    private let previewParameters = LockedValue(FilterParameters())

    init(
        cameraService: (any CameraService)? = nil,
        imageProcessor: (any ImageProcessor)? = nil,
        presetRepository: (any PresetRepository)? = nil,
        photoLibraryService: (any PhotoLibraryService)? = nil,
        favoriteStore: (any FavoriteStore)? = nil,
        settingsStore: (any SettingsStore)? = nil
    ) {
        self.cameraService = cameraService ?? DefaultCameraService()
        self.imageProcessor = imageProcessor ?? DefaultImageProcessor()
        self.presetRepository = presetRepository ?? BundlePresetRepository()
        self.photoLibraryService = photoLibraryService ?? DefaultPhotoLibraryService()
        self.favoriteStore = favoriteStore ?? UserDefaultsFavoriteStore()
        self.settingsStore = settingsStore ?? UserDefaultsSettingsStore()
        isDateStampEnabled = self.settingsStore.isDateStampEnabled
        loadPresets()
    }

    /// Crop + フィルター適用済みのプレビューフレームを供給する。
    /// パラメータはフレームごとに読み直すため、プリセット切替に即時追従する
    func makePreviewStream() -> AsyncStream<CIImage> {
        let source = cameraService.makePreviewStream()
        let processor = imageProcessor
        let parameters = previewParameters
        return AsyncStream { continuation in
            let task = Task.detached {
                for await frame in source {
                    continuation.yield(processor.process(frame, with: parameters.value))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func selectPreset(_ preset: CameraPreset) {
        currentPreset = preset
        previewParameters.value = preset.filterParameters
    }

    func toggleFavorite(_ preset: CameraPreset) {
        let isFavorite = !favoritePresetIDs.contains(preset.id)
        favoriteStore.setFavorite(preset.id, isFavorite: isFavorite)
        favoritePresetIDs = favoriteStore.favoriteIDs()
        presets = sortedForDisplay(orderedPresets)
    }

    func isFavorite(_ preset: CameraPreset) -> Bool {
        favoritePresetIDs.contains(preset.id)
    }

    func switchCamera() async {
        guard status == .running, !isSwitchingCamera else { return }
        isSwitchingCamera = true
        defer { isSwitchingCamera = false }
        // 失敗時は現在のカメラのまま継続する
        try? await cameraService.switchCamera()
    }

    func toggleFlash() async {
        isFlashEnabled.toggle()
        await cameraService.setFlashEnabled(isFlashEnabled)
    }

    func toggleDateStamp() {
        isDateStampEnabled.toggle()
        settingsStore.isDateStampEnabled = isDateStampEnabled
    }

    /// 露出補正（EV）。UI からは -2〜+2 の範囲で渡す
    func adjustExposure(_ bias: Double) async {
        guard status == .running else { return }
        let clamped = min(max(bias, Self.exposureRange.lowerBound), Self.exposureRange.upperBound)
        exposureBias = clamped
        // 失敗しても撮影は継続できるため UI には出さない
        try? await cameraService.setExposureBias(Float(clamped))
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
        orderedPresets = (try? presetRepository.loadPresets()) ?? []
        favoritePresetIDs = favoriteStore.favoriteIDs()
        presets = sortedForDisplay(orderedPresets)
        if let first = presets.first {
            selectPreset(first)
        }
    }

    /// お気に入りを先頭に、それ以外は定義順のまま並べる（安定ソート）
    private func sortedForDisplay(_ presets: [CameraPreset]) -> [CameraPreset] {
        let favorites = presets.filter { favoritePresetIDs.contains($0.id) }
        let others = presets.filter { !favoritePresetIDs.contains($0.id) }
        return favorites + others
    }

    /// 撮影データにプレビューと同じ Crop + フィルターを適用し、
    /// サムネイル用 CGImage と保存用データを生成する
    private func processCapturedPhoto(_ data: Data) -> (cgImage: CGImage, data: Data)? {
        guard let source = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        let parameters = currentPreset?.filterParameters ?? FilterParameters()
        var processed = imageProcessor.process(source, with: parameters)
        if isDateStampEnabled {
            processed = imageProcessor.stampDate(Date(), on: processed)
        }
        guard let cgImage = imageProcessor.renderCGImage(from: processed),
              let photoData = imageProcessor.makePhotoData(from: processed) else {
            return nil
        }
        return (cgImage, photoData)
    }
}
