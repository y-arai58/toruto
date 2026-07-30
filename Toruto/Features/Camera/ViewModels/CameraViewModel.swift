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
    /// プレビューの最初のフレームが届いたか（起動オーバーレイの退場条件）
    private(set) var hasPreviewFrame = false
    private(set) var isCapturing = false
    private(set) var isSwitchingCamera = false
    private(set) var exposureBias: Double = 0
    private(set) var isFlashEnabled = false
    private(set) var isDateStampEnabled = false
    private(set) var availableLenses: [CameraLens] = []
    private(set) var currentLens: CameraLens = .wide
    /// 中央フレームのスケール（視野に対する割合）。レンズ別の範囲にクランプされる
    private(set) var frameScale: CGFloat = CameraFrame.defaultScale

    /// 表示用の換算焦点距離（mm）
    var displayFocalLength: Int {
        CameraFrame.equivalentFocalLength(
            baseFocalLength: currentLens.equivalentFocalLength,
            scale: frameScale
        )
    }
    private(set) var lastCapturedImage: UIImage?
    /// カスタムプリセット作成中の下書き
    struct PresetDraft: Equatable {
        var name: String
        var parameters: FilterParameters
    }

    /// 表示順のプリセット一覧（お気に入りが先頭、それ以外は定義順）
    private(set) var presets: [CameraPreset] = []
    private(set) var currentPreset: CameraPreset?
    private(set) var favoritePresetIDs: Set<String> = []
    private(set) var customPresetIDs: Set<String> = []
    private(set) var draft: PresetDraft?
    private(set) var saveError: SaveError?

    private let cameraService: any CameraService
    private let imageProcessor: any ImageProcessor
    private let presetRepository: any PresetRepository
    private let photoLibraryService: any PhotoLibraryService
    private let favoriteStore: any FavoriteStore
    private let settingsStore: any SettingsStore
    private let shutterSoundPlayer: any ShutterSoundPlayer
    private let customPresetStore: any CustomPresetStore
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
        settingsStore: (any SettingsStore)? = nil,
        shutterSoundPlayer: (any ShutterSoundPlayer)? = nil,
        customPresetStore: (any CustomPresetStore)? = nil
    ) {
        self.cameraService = cameraService ?? DefaultCameraService()
        self.imageProcessor = imageProcessor ?? DefaultImageProcessor()
        self.presetRepository = presetRepository ?? BundlePresetRepository()
        self.photoLibraryService = photoLibraryService ?? DefaultPhotoLibraryService()
        self.favoriteStore = favoriteStore ?? UserDefaultsFavoriteStore()
        self.settingsStore = settingsStore ?? UserDefaultsSettingsStore()
        self.shutterSoundPlayer = shutterSoundPlayer ?? SystemShutterSoundPlayer()
        self.customPresetStore = customPresetStore ?? UserDefaultsCustomPresetStore()
        isDateStampEnabled = self.settingsStore.isDateStampEnabled
        frameScale = CameraFrame.clampScale(
            CGFloat(self.settingsStore.frameScale),
            baseFocalLength: currentLens.equivalentFocalLength
        )
        loadPresets()
    }

    /// フィルター適用済みの全画角プレビューフレームを供給する（Crop は保存時のみ）。
    /// パラメータはフレームごとに読み直すため、プリセット切替に即時追従する
    func makePreviewStream() -> AsyncStream<CIImage> {
        let source = cameraService.makePreviewStream()
        let processor = imageProcessor
        let parameters = previewParameters
        return AsyncStream { continuation in
            let task = Task.detached { [weak self] in
                var isFirstFrame = true
                for await frame in source {
                    continuation.yield(processor.applyFilters(to: frame, with: parameters.value))
                    // 通知は最初の 1 回だけ。毎フレーム MainActor へ跳ぶのを避ける
                    if isFirstFrame {
                        isFirstFrame = false
                        await self?.markPreviewFrameReceived()
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func markPreviewFrameReceived() {
        hasPreviewFrame = true
    }

    func selectPreset(_ preset: CameraPreset) {
        currentPreset = preset
        previewParameters.value = preset.filterParameters
    }

    /// 現在と異なるプリセットをランダムに選ぶ（1 つしかない場合はそのまま）
    func selectRandomPreset() {
        let candidates = presets.filter { $0.id != currentPreset?.id }
        guard let preset = candidates.randomElement() else { return }
        selectPreset(preset)
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

    func isCustom(_ preset: CameraPreset) -> Bool {
        customPresetIDs.contains(preset.id)
    }

    /// 複製元を指定してカスタムプリセットの編集を開始する。調整値はプレビューへ即時反映される
    func beginCustomizing(from preset: CameraPreset) {
        draft = PresetDraft(name: "\(preset.displayName) +", parameters: preset.filterParameters)
        previewParameters.value = preset.filterParameters
    }

    func updateDraftParameters(_ parameters: FilterParameters) {
        guard draft != nil else { return }
        draft?.parameters = parameters
        previewParameters.value = parameters
    }

    /// 下書きを保存して選択状態にする
    func saveDraft(name: String) {
        guard let draft else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let preset = CameraPreset(
            id: "custom_\(UUID().uuidString)",
            displayName: trimmed.isEmpty ? draft.name : trimmed,
            filterParameters: draft.parameters
        )
        customPresetStore.add(preset)
        self.draft = nil
        reloadPresets()
        selectPreset(preset)
    }

    /// 下書きを破棄してプレビューを現在のプリセットに戻す
    func cancelDraft() {
        draft = nil
        previewParameters.value = currentPreset?.filterParameters ?? FilterParameters()
    }

    func deleteCustomPreset(_ preset: CameraPreset) {
        guard isCustom(preset) else { return }
        customPresetStore.delete(id: preset.id)
        favoriteStore.setFavorite(preset.id, isFavorite: false)
        reloadPresets()
        if currentPreset?.id == preset.id, let first = presets.first {
            selectPreset(first)
        }
    }

    func switchCamera() async {
        guard status == .running, !isSwitchingCamera else { return }
        isSwitchingCamera = true
        defer { isSwitchingCamera = false }
        // 失敗時は現在のカメラのまま継続する
        try? await cameraService.switchCamera()
        // 位置が変わるとレンズは wide に戻る
        currentLens = .wide
        availableLenses = await cameraService.availableLenses()
        setFrameScale(frameScale)
    }

    /// mm プリセット: レンズを切り替え、フレームを全画角（= 基準 mm）に戻す
    func selectLens(_ lens: CameraLens) async {
        guard status == .running, availableLenses.contains(lens) else { return }
        if lens != currentLens {
            do {
                try await cameraService.selectLens(lens)
                currentLens = lens
            } catch {
                // 失敗時は現在のレンズのまま継続する
                return
            }
        }
        setFrameScale(1.0)
        commitFrameScale()
    }

    /// ピンチ中のフレームスケール更新（レンズ別範囲にクランプ）
    func setFrameScale(_ scale: CGFloat) {
        frameScale = CameraFrame.clampScale(
            scale,
            baseFocalLength: currentLens.equivalentFocalLength
        )
    }

    /// ピンチ終了時に永続化する
    func commitFrameScale() {
        settingsStore.frameScale = Double(frameScale)
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
            availableLenses = await cameraService.availableLenses()
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
        shutterSoundPlayer.play()
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
        reloadPresets()
        if let first = presets.first {
            selectPreset(first)
        }
    }

    /// バンドル定義（全パック） + カスタムを読み込み、表示順を組み立てる
    private func reloadPresets() {
        let bundled = ((try? presetRepository.loadPacks()) ?? []).flatMap(\.presets)
        let custom = customPresetStore.loadCustomPresets()
        customPresetIDs = Set(custom.map(\.id))
        orderedPresets = bundled + custom
        favoritePresetIDs = favoriteStore.favoriteIDs()
        presets = sortedForDisplay(orderedPresets)
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
        var processed = imageProcessor.process(source, with: parameters, frameScale: frameScale)
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
