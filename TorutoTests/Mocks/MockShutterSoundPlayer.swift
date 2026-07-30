@testable import Toruto

final class MockShutterSoundPlayer: ShutterSoundPlayer {
    private(set) var playCallCount = 0

    func play() {
        playCallCount += 1
    }
}
