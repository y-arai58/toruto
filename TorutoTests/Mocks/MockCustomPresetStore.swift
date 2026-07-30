@testable import Toruto

final class MockCustomPresetStore: CustomPresetStore {
    private var presets: [CameraPreset]

    init(presets: [CameraPreset] = []) {
        self.presets = presets
    }

    func loadCustomPresets() -> [CameraPreset] {
        presets
    }

    func add(_ preset: CameraPreset) {
        presets.append(preset)
    }

    func delete(id: String) {
        presets.removeAll { $0.id == id }
    }
}
