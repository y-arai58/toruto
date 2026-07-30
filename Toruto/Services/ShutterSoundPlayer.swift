import AudioToolbox

/// シャッター音の再生を担う
protocol ShutterSoundPlayer: AnyObject {
    func play()
}

/// iOS 標準のカメラシャッター音を鳴らす標準実装
final class SystemShutterSoundPlayer: ShutterSoundPlayer {
    private static let systemShutterSoundID: SystemSoundID = 1108

    func play() {
        AudioServicesPlaySystemSound(Self.systemShutterSoundID)
    }
}
