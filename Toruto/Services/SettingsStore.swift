import Foundation

/// 撮影設定の永続化を担う
protocol SettingsStore: AnyObject {
    var isDateStampEnabled: Bool { get set }
    /// 中央フレームのスケール（視野に対する割合）
    var frameScale: Double { get set }
}

/// UserDefaults による標準実装
final class UserDefaultsSettingsStore: SettingsStore {
    private static let dateStampKey = "isDateStampEnabled"
    private static let frameScaleKey = "frameScale"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isDateStampEnabled: Bool {
        get { defaults.bool(forKey: Self.dateStampKey) }
        set { defaults.set(newValue, forKey: Self.dateStampKey) }
    }

    var frameScale: Double {
        get {
            guard defaults.object(forKey: Self.frameScaleKey) != nil else {
                return 0.8
            }
            return defaults.double(forKey: Self.frameScaleKey)
        }
        set { defaults.set(newValue, forKey: Self.frameScaleKey) }
    }
}
