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
        favoriteStore: MockFavoriteStore = MockFavoriteStore()
    ) -> CameraViewModel {
        CameraViewModel(
            cameraService: service,
            imageProcessor: processor,
            presetRepository: repository,
            photoLibraryService: photoLibrary,
            favoriteStore: favoriteStore
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
