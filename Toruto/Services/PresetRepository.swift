import Foundation

enum PresetRepositoryError: Error {
    case resourceNotFound
}

/// カメラプリセット定義の読み込みを担う
protocol PresetRepository: AnyObject {
    /// 表示順どおりのパック一覧を返す
    func loadPacks() throws -> [CameraPresetPack]
}

/// Resources/Filters/presets.json から読み込む標準実装
final class BundlePresetRepository: PresetRepository {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadPacks() throws -> [CameraPresetPack] {
        guard let url = bundle.url(forResource: "presets", withExtension: "json") else {
            throw PresetRepositoryError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CameraPresetPack].self, from: data)
    }
}
