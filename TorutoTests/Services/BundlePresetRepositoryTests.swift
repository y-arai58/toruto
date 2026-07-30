import Foundation
import Testing
@testable import Toruto

struct BundlePresetRepositoryTests {
    @Test
    func アプリバンドルから9プリセットを読み込める() throws {
        let repository = BundlePresetRepository(bundle: .main)
        let presets = try repository.loadPresets()

        #expect(presets.count == 9)
        #expect(presets.first?.id == "ccd")
        #expect(Set(presets.map(\.id)).count == presets.count)
    }

    @Test
    func リソースがないバンドルではエラーになる() {
        let repository = BundlePresetRepository(bundle: Bundle(for: MockImageProcessor.self))
        #expect(throws: PresetRepositoryError.self) {
            try repository.loadPresets()
        }
    }
}
