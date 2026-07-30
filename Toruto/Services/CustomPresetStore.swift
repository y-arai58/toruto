import Foundation

/// カスタムプリセットの永続化を担う
protocol CustomPresetStore: AnyObject {
    func loadCustomPresets() -> [CameraPreset]
    func add(_ preset: CameraPreset)
    func delete(id: String)
}

/// UserDefaults に JSON で保存する標準実装
final class UserDefaultsCustomPresetStore: CustomPresetStore {
    private static let key = "customPresets"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCustomPresets() -> [CameraPreset] {
        guard let data = defaults.data(forKey: Self.key),
              let presets = try? JSONDecoder().decode([CameraPreset].self, from: data) else {
            return []
        }
        return presets
    }

    func add(_ preset: CameraPreset) {
        var presets = loadCustomPresets()
        presets.append(preset)
        save(presets)
    }

    func delete(id: String) {
        save(loadCustomPresets().filter { $0.id != id })
    }

    private func save(_ presets: [CameraPreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
