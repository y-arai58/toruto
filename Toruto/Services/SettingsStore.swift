import Foundation

/// 撮影設定の永続化を担う
protocol SettingsStore: AnyObject {
    var isDateStampEnabled: Bool { get set }
    var shutterSound: ShutterSound { get set }
}

/// UserDefaults による標準実装
final class UserDefaultsSettingsStore: SettingsStore {
    private static let dateStampKey = "isDateStampEnabled"
    private static let shutterSoundKey = "shutterSound"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isDateStampEnabled: Bool {
        get { defaults.bool(forKey: Self.dateStampKey) }
        set { defaults.set(newValue, forKey: Self.dateStampKey) }
    }

    var shutterSound: ShutterSound {
        get {
            guard let raw = defaults.string(forKey: Self.shutterSoundKey),
                  let sound = ShutterSound(rawValue: raw) else {
                return .classic
            }
            return sound
        }
        set { defaults.set(newValue.rawValue, forKey: Self.shutterSoundKey) }
    }
}
