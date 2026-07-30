@testable import Toruto

final class MockPresetRepository: PresetRepository {
    var result: Result<[CameraPresetPack], Error>

    init(presets: [CameraPreset] = [
        CameraPreset(id: "test", displayName: "Test", filterParameters: FilterParameters()),
    ]) {
        result = .success([
            CameraPresetPack(id: "test_pack", displayName: "Test Pack", presets: presets),
        ])
    }

    func loadPacks() throws -> [CameraPresetPack] {
        try result.get()
    }
}
