@testable import Toruto

final class MockSettingsStore: SettingsStore {
    var isDateStampEnabled: Bool
    var shutterSound: ShutterSound

    init(isDateStampEnabled: Bool = false, shutterSound: ShutterSound = .classic) {
        self.isDateStampEnabled = isDateStampEnabled
        self.shutterSound = shutterSound
    }
}
