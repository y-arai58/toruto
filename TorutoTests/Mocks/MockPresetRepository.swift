@testable import Toruto

final class MockPresetRepository: PresetRepository {
    var result: Result<[CameraPreset], Error>

    init(presets: [CameraPreset] = [
        CameraPreset(id: "test", displayName: "Test", filterParameters: FilterParameters()),
    ]) {
        result = .success(presets)
    }

    func loadPresets() throws -> [CameraPreset] {
        try result.get()
    }
}
