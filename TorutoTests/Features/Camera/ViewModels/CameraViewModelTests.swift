import Testing
import UIKit
@testable import Toruto

@MainActor
struct CameraViewModelTests {
    private func makeViewModel(
        service: MockCameraService = MockCameraService(),
        processor: MockImageProcessor = MockImageProcessor(),
        repository: MockPresetRepository = MockPresetRepository(),
        photoLibrary: MockPhotoLibraryService = MockPhotoLibraryService(),
        favoriteStore: MockFavoriteStore = MockFavoriteStore(),
        settingsStore: MockSettingsStore = MockSettingsStore(),
        soundPlayer: MockShutterSoundPlayer = MockShutterSoundPlayer(),
        customPresetStore: MockCustomPresetStore = MockCustomPresetStore()
    ) -> CameraViewModel {
        CameraViewModel(
            cameraService: service,
            imageProcessor: processor,
            presetRepository: repository,
            photoLibraryService: photoLibrary,
            favoriteStore: favoriteStore,
            settingsStore: settingsStore,
            shutterSoundPlayer: soundPlayer,
            customPresetStore: customPresetStore
        )
    }

    @Test
    func init_プリセットを読み込み先頭を選択する() {
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
            CameraPreset(id: "b", displayName: "B", filterParameters: FilterParameters()),
        ])
        let viewModel = makeViewModel(repository: repository)

        #expect(viewModel.presets.count == 2)
        #expect(viewModel.currentPreset?.id == "a")
    }

    @Test
    func init_プリセット読み込み失敗でもクラッシュしない() {
        let repository = MockPresetRepository()
        repository.result = .failure(PresetRepositoryError.resourceNotFound)
        let viewModel = makeViewModel(repository: repository)

        #expect(viewModel.presets.isEmpty)
        #expect(viewModel.currentPreset == nil)
    }

    @Test
    func selectPreset_currentPresetが切り替わる() {
        let presetB = CameraPreset(id: "b", displayName: "B", filterParameters: FilterParameters())
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
            presetB,
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.selectPreset(presetB)

        #expect(viewModel.currentPreset?.id == "b")
    }

    @Test
    func selectPreset_プレビューのパラメータに即時反映される() async {
        var parametersA = FilterParameters()
        parametersA.saturation = 2
        var parametersB = FilterParameters()
        parametersB.saturation = 3
        let presetA = CameraPreset(id: "a", displayName: "A", filterParameters: parametersA)
        let presetB = CameraPreset(id: "b", displayName: "B", filterParameters: parametersB)

        let service = MockCameraService()
        let processor = MockImageProcessor()
        let viewModel = makeViewModel(
            service: service,
            processor: processor,
            repository: MockPresetRepository(presets: [presetA, presetB])
        )

        let stream = viewModel.makePreviewStream()
        var iterator = stream.makeAsyncIterator()
        let frame = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 3, height: 4))

        service.emitPreviewFrame(frame)
        _ = await iterator.next()
        #expect(processor.lastParameters == parametersA)

        viewModel.selectPreset(presetB)
        service.emitPreviewFrame(frame)
        _ = await iterator.next()
        #expect(processor.lastParameters == parametersB)
    }

    @Test
    func startSession_成功時はrunningになる() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)

        await viewModel.startSession()

        #expect(viewModel.status == .running)
        #expect(service.startCallCount == 1)
    }

    @Test
    func startSession_権限拒否時はpermissionDeniedになる() async {
        let service = MockCameraService()
        service.startError = CameraServiceError.permissionDenied
        let viewModel = makeViewModel(service: service)

        await viewModel.startSession()

        #expect(viewModel.status == .permissionDenied)
    }

    @Test
    func startSession_デバイス不可時はunavailableになる() async {
        let service = MockCameraService()
        service.startError = CameraServiceError.deviceUnavailable
        let viewModel = makeViewModel(service: service)

        await viewModel.startSession()

        #expect(viewModel.status == .unavailable)
    }

    @Test
    func stopSession_実行中に停止するとidleに戻る() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.stopSession()

        #expect(viewModel.status == .idle)
        #expect(service.stopCallCount == 1)
    }

    @Test
    func switchCamera_実行中はサービスを呼ぶ() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.switchCamera()

        #expect(service.switchCameraCallCount == 1)
        #expect(viewModel.isSwitchingCamera == false)
    }

    @Test
    func switchCamera_起動前は呼ばない() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)

        await viewModel.switchCamera()

        #expect(service.switchCameraCallCount == 0)
    }

    @Test
    func switchCamera_失敗してもrunningのまま継続する() async {
        let service = MockCameraService()
        service.switchCameraError = CameraServiceError.deviceUnavailable
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.switchCamera()

        #expect(viewModel.status == .running)
        #expect(viewModel.isSwitchingCamera == false)
    }

    @Test
    func selectRandomPreset_現在と異なるプリセットが選ばれる() {
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
            CameraPreset(id: "b", displayName: "B", filterParameters: FilterParameters()),
        ])
        let viewModel = makeViewModel(repository: repository)
        #expect(viewModel.currentPreset?.id == "a")

        for _ in 0..<10 {
            let before = viewModel.currentPreset?.id
            viewModel.selectRandomPreset()
            #expect(viewModel.currentPreset?.id != before)
        }
    }

    @Test
    func selectRandomPreset_プリセットが1つなら変わらない() {
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.selectRandomPreset()

        #expect(viewModel.currentPreset?.id == "a")
    }

    @Test
    func toggleFavorite_登録するとストアへ保存され先頭に並ぶ() {
        let presetC = CameraPreset(id: "c", displayName: "C", filterParameters: FilterParameters())
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
            CameraPreset(id: "b", displayName: "B", filterParameters: FilterParameters()),
            presetC,
        ])
        let store = MockFavoriteStore()
        let viewModel = makeViewModel(repository: repository, favoriteStore: store)

        viewModel.toggleFavorite(presetC)

        #expect(viewModel.isFavorite(presetC))
        #expect(store.favoriteIDs() == ["c"])
        #expect(viewModel.presets.map(\.id) == ["c", "a", "b"])
    }

    @Test
    func toggleFavorite_解除すると定義順に戻る() {
        let presetC = CameraPreset(id: "c", displayName: "C", filterParameters: FilterParameters())
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
            CameraPreset(id: "b", displayName: "B", filterParameters: FilterParameters()),
            presetC,
        ])
        let store = MockFavoriteStore(favorites: ["c"])
        let viewModel = makeViewModel(repository: repository, favoriteStore: store)
        #expect(viewModel.presets.map(\.id) == ["c", "a", "b"])

        viewModel.toggleFavorite(presetC)

        #expect(!viewModel.isFavorite(presetC))
        #expect(viewModel.presets.map(\.id) == ["a", "b", "c"])
    }

    @Test
    func init_保存済みのお気に入りを読み込み先頭のプリセットを選択する() {
        let repository = MockPresetRepository(presets: [
            CameraPreset(id: "a", displayName: "A", filterParameters: FilterParameters()),
            CameraPreset(id: "b", displayName: "B", filterParameters: FilterParameters()),
        ])
        let store = MockFavoriteStore(favorites: ["b"])
        let viewModel = makeViewModel(repository: repository, favoriteStore: store)

        #expect(viewModel.presets.map(\.id) == ["b", "a"])
        #expect(viewModel.currentPreset?.id == "b")
    }

    @Test
    func saveDraft_カスタムプリセットが追加され選択される() {
        let store = MockCustomPresetStore()
        let viewModel = makeViewModel(customPresetStore: store)
        let source = viewModel.presets[0]

        viewModel.beginCustomizing(from: source)
        var adjusted = source.filterParameters
        adjusted.saturation = 1.3
        viewModel.updateDraftParameters(adjusted)
        viewModel.saveDraft(name: "My Camera")

        #expect(viewModel.draft == nil)
        #expect(store.loadCustomPresets().count == 1)
        #expect(viewModel.currentPreset?.displayName == "My Camera")
        #expect(viewModel.currentPreset?.filterParameters.saturation == 1.3)
        #expect(viewModel.isCustom(viewModel.currentPreset!))
    }

    @Test
    func cancelDraft_破棄するとプレビューが現在のプリセットに戻る() {
        let viewModel = makeViewModel()
        let source = viewModel.presets[0]

        viewModel.beginCustomizing(from: source)
        viewModel.cancelDraft()

        #expect(viewModel.draft == nil)
        #expect(viewModel.presets.count == 1)
    }

    @Test
    func saveDraft_空の名前はデフォルト名で保存される() {
        let store = MockCustomPresetStore()
        let viewModel = makeViewModel(customPresetStore: store)

        viewModel.beginCustomizing(from: viewModel.presets[0])
        viewModel.saveDraft(name: "   ")

        #expect(store.loadCustomPresets().first?.displayName == "Test +")
    }

    @Test
    func deleteCustomPreset_削除すると一覧から消え先頭が選択される() {
        let custom = CameraPreset(id: "custom_x", displayName: "X", filterParameters: FilterParameters())
        let store = MockCustomPresetStore(presets: [custom])
        let viewModel = makeViewModel(customPresetStore: store)
        viewModel.selectPreset(custom)

        viewModel.deleteCustomPreset(custom)

        #expect(store.loadCustomPresets().isEmpty)
        #expect(!viewModel.presets.contains { $0.id == "custom_x" })
        #expect(viewModel.currentPreset?.id == "test")
    }

    @Test
    func deleteCustomPreset_バンドル定義は削除できない() {
        let viewModel = makeViewModel()
        let bundled = viewModel.presets[0]

        viewModel.deleteCustomPreset(bundled)

        #expect(viewModel.presets.contains { $0.id == bundled.id })
    }

    @Test
    func init_カスタムプリセットも一覧に読み込まれる() {
        let custom = CameraPreset(id: "custom_x", displayName: "X", filterParameters: FilterParameters())
        let store = MockCustomPresetStore(presets: [custom])
        let viewModel = makeViewModel(customPresetStore: store)

        #expect(viewModel.presets.map(\.id) == ["test", "custom_x"])
        #expect(viewModel.isCustom(custom))
    }

    @Test
    func selectShutterSound_選択が永続化される() {
        let store = MockSettingsStore()
        let viewModel = makeViewModel(settingsStore: store)

        viewModel.selectShutterSound(.film)

        #expect(viewModel.shutterSound == .film)
        #expect(store.shutterSound == .film)
    }

    @Test
    func capturePhoto_選択中のシャッター音が鳴る() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let player = MockShutterSoundPlayer()
        let viewModel = makeViewModel(
            service: service,
            settingsStore: MockSettingsStore(shutterSound: .digital),
            soundPlayer: player
        )
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(player.playedSounds == [.digital])
    }

    @Test
    func capturePhoto_起動前はシャッター音も鳴らない() async {
        let player = MockShutterSoundPlayer()
        let viewModel = makeViewModel(soundPlayer: player)

        await viewModel.capturePhoto()

        #expect(player.playedSounds.isEmpty)
    }

    @Test
    func toggleDateStamp_切り替えが永続化される() {
        let store = MockSettingsStore()
        let viewModel = makeViewModel(settingsStore: store)

        viewModel.toggleDateStamp()

        #expect(viewModel.isDateStampEnabled)
        #expect(store.isDateStampEnabled)
    }

    @Test
    func capturePhoto_日付スタンプONのとき焼き込みが行われる() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let processor = MockImageProcessor()
        let viewModel = makeViewModel(
            service: service,
            processor: processor,
            settingsStore: MockSettingsStore(isDateStampEnabled: true)
        )
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(processor.stampDateCallCount == 1)
    }

    @Test
    func capturePhoto_日付スタンプOFFのとき焼き込みは行われない() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let processor = MockImageProcessor()
        let viewModel = makeViewModel(service: service, processor: processor)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(processor.stampDateCallCount == 0)
    }

    @Test
    func toggleFlash_ONOFFがサービスへ伝わる() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)

        await viewModel.toggleFlash()
        #expect(viewModel.isFlashEnabled)
        #expect(service.lastFlashEnabled == true)

        await viewModel.toggleFlash()
        #expect(!viewModel.isFlashEnabled)
        #expect(service.lastFlashEnabled == false)
    }

    @Test
    func adjustExposure_範囲内の値をサービスへ渡す() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.adjustExposure(1.5)

        #expect(viewModel.exposureBias == 1.5)
        #expect(service.lastExposureBias == 1.5)
    }

    @Test
    func adjustExposure_範囲外の値はクランプされる() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.adjustExposure(5)

        #expect(viewModel.exposureBias == 2)
        #expect(service.lastExposureBias == 2)
    }

    @Test
    func adjustExposure_起動前は何もしない() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)

        await viewModel.adjustExposure(1)

        #expect(viewModel.exposureBias == 0)
        #expect(service.lastExposureBias == nil)
    }

    @Test
    func startSession_利用可能なレンズを読み込む() async {
        let service = MockCameraService()
        service.lenses = [.ultraWide, .wide, .telephoto]
        let viewModel = makeViewModel(service: service)

        await viewModel.startSession()

        #expect(viewModel.availableLenses == [.ultraWide, .wide, .telephoto])
        #expect(viewModel.currentLens == .wide)
    }

    @Test
    func selectLens_利用可能なレンズへ切り替えられる() async {
        let service = MockCameraService()
        service.lenses = [.ultraWide, .wide]
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.selectLens(.ultraWide)

        #expect(viewModel.currentLens == .ultraWide)
        #expect(service.selectedLenses == [.ultraWide])
    }

    @Test
    func selectLens_利用不可のレンズは無視される() async {
        let service = MockCameraService()
        service.lenses = [.wide]
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.selectLens(.telephoto)

        #expect(viewModel.currentLens == .wide)
        #expect(service.selectedLenses.isEmpty)
    }

    @Test
    func selectLens_失敗時は現在のレンズを維持する() async {
        let service = MockCameraService()
        service.lenses = [.ultraWide, .wide]
        service.selectLensError = CameraServiceError.deviceUnavailable
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.selectLens(.ultraWide)

        #expect(viewModel.currentLens == .wide)
    }

    @Test
    func switchCamera_レンズがwideにリセットされる() async {
        let service = MockCameraService()
        service.lenses = [.ultraWide, .wide]
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()
        await viewModel.selectLens(.ultraWide)

        await viewModel.switchCamera()

        #expect(viewModel.currentLens == .wide)
    }

    @Test
    func capturePhoto_成功時はCropとフィルターを適用した画像を保持する() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let processor = MockImageProcessor()
        let viewModel = makeViewModel(service: service, processor: processor)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(viewModel.lastCapturedImage != nil)
        #expect(service.captureCallCount == 1)
        #expect(processor.processCallCount == 1)
        #expect(viewModel.isCapturing == false)
    }

    @Test
    func capturePhoto_成功時は加工済みデータを保存する() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let photoLibrary = MockPhotoLibraryService()
        let viewModel = makeViewModel(service: service, photoLibrary: photoLibrary)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(photoLibrary.savedData.count == 1)
        #expect(viewModel.saveError == nil)
    }

    @Test
    func capturePhoto_保存権限拒否時はpermissionDeniedを通知する() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let photoLibrary = MockPhotoLibraryService()
        photoLibrary.saveError = PhotoLibraryError.permissionDenied
        let viewModel = makeViewModel(service: service, photoLibrary: photoLibrary)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(viewModel.saveError == .permissionDenied)
    }

    @Test
    func capturePhoto_保存失敗時はfailedを通知し次の撮影でリセットされる() async {
        let service = MockCameraService()
        service.captureResult = .success(Self.makeImageData())
        let photoLibrary = MockPhotoLibraryService()
        photoLibrary.saveError = PhotoLibraryError.saveFailed
        let viewModel = makeViewModel(service: service, photoLibrary: photoLibrary)
        await viewModel.startSession()

        await viewModel.capturePhoto()
        #expect(viewModel.saveError == .failed)

        photoLibrary.saveError = nil
        await viewModel.capturePhoto()
        #expect(viewModel.saveError == nil)
    }

    @Test
    func capturePhoto_起動前は撮影しない() async {
        let service = MockCameraService()
        let viewModel = makeViewModel(service: service)

        await viewModel.capturePhoto()

        #expect(service.captureCallCount == 0)
        #expect(viewModel.lastCapturedImage == nil)
    }

    @Test
    func capturePhoto_失敗時は画像を保持しない() async {
        let service = MockCameraService()
        service.captureResult = .failure(CameraServiceError.captureFailed)
        let viewModel = makeViewModel(service: service)
        await viewModel.startSession()

        await viewModel.capturePhoto()

        #expect(viewModel.lastCapturedImage == nil)
        #expect(viewModel.isCapturing == false)
    }

    private static func makeImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.pngData { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}
