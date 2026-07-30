import AudioToolbox
import Foundation

/// シャッター音の再生を担う
protocol ShutterSoundPlayer: AnyObject {
    func play(_ sound: ShutterSound)
}

/// AudioToolbox による標準実装。
/// classic はシステムのシャッター音（1108）、それ以外はバンドル内の wav を鳴らす
final class SystemShutterSoundPlayer: ShutterSoundPlayer {
    /// iOS 標準のカメラシャッター音
    private static let systemShutterSoundID: SystemSoundID = 1108

    private let bundle: Bundle
    private var cachedSoundIDs: [ShutterSound: SystemSoundID] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    deinit {
        for id in cachedSoundIDs.values {
            AudioServicesDisposeSystemSoundID(id)
        }
    }

    func play(_ sound: ShutterSound) {
        guard let soundID = soundID(for: sound) else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    private func soundID(for sound: ShutterSound) -> SystemSoundID? {
        guard let fileName = sound.fileName else {
            return Self.systemShutterSoundID
        }
        if let cached = cachedSoundIDs[sound] {
            return cached
        }
        guard let url = bundle.url(forResource: fileName, withExtension: "wav") else {
            return Self.systemShutterSoundID
        }
        var soundID: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(url as CFURL, &soundID) == kAudioServicesNoError else {
            return Self.systemShutterSoundID
        }
        cachedSoundIDs[sound] = soundID
        return soundID
    }
}
