@testable import Toruto

final class MockSettingsStore: SettingsStore {
    var isDateStampEnabled: Bool

    init(isDateStampEnabled: Bool = false) {
        self.isDateStampEnabled = isDateStampEnabled
    }
}
