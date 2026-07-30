import Foundation
import Testing
@testable import Toruto

struct BundlePresetRepositoryTests {
    @Test
    func アプリバンドルから2パック12プリセットを読み込める() throws {
        let repository = BundlePresetRepository(bundle: .main)
        let packs = try repository.loadPacks()

        #expect(packs.count == 2)
        #expect(packs.map(\.id) == ["essentials", "mono"])

        let presets = packs.flatMap(\.presets)
        #expect(presets.count == 12)
        #expect(presets.first?.id == "ccd")
        #expect(Set(presets.map(\.id)).count == presets.count)
    }

    @Test
    func リソースがないバンドルではエラーになる() {
        let repository = BundlePresetRepository(bundle: Bundle(for: MockImageProcessor.self))
        #expect(throws: PresetRepositoryError.self) {
            try repository.loadPacks()
        }
    }
}
