@testable import Toruto

final class MockSettingsStore: SettingsStore {
    var isDateStampEnabled: Bool
    var shutterSound: ShutterSound
    var frameScale: Double

    init(
        isDateStampEnabled: Bool = false,
        shutterSound: ShutterSound = .classic,
        frameScale: Double = 0.8
    ) {
        self.isDateStampEnabled = isDateStampEnabled
        self.shutterSound = shutterSound
        self.frameScale = frameScale
    }
}
