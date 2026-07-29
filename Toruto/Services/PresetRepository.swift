import Foundation

enum PresetRepositoryError: Error {
    case resourceNotFound
}

/// カメラプリセット定義の読み込みを担う
protocol PresetRepository: AnyObject {
    /// 表示順どおりのプリセット一覧を返す
    func loadPresets() throws -> [CameraPreset]
}

/// Resources/Filters/presets.json から読み込む標準実装
final class BundlePresetRepository: PresetRepository {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadPresets() throws -> [CameraPreset] {
        guard let url = bundle.url(forResource: "presets", withExtension: "json") else {
            throw PresetRepositoryError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CameraPreset].self, from: data)
    }
}
