@testable import Toruto

final class MockShutterSoundPlayer: ShutterSoundPlayer {
    private(set) var playedSounds: [ShutterSound] = []

    func play(_ sound: ShutterSound) {
        playedSounds.append(sound)
    }
}
