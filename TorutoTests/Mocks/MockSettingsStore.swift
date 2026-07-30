@testable import Toruto

final class MockSettingsStore: SettingsStore {
    var isDateStampEnabled: Bool
    var frameScale: Double

    init(isDateStampEnabled: Bool = false, frameScale: Double = 0.8) {
        self.isDateStampEnabled = isDateStampEnabled
        self.frameScale = frameScale
    }
}
