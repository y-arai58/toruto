import Foundation

/// 撮影設定の永続化を担う
protocol SettingsStore: AnyObject {
    var isDateStampEnabled: Bool { get set }
}

/// UserDefaults による標準実装
final class UserDefaultsSettingsStore: SettingsStore {
    private static let dateStampKey = "isDateStampEnabled"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isDateStampEnabled: Bool {
        get { defaults.bool(forKey: Self.dateStampKey) }
        set { defaults.set(newValue, forKey: Self.dateStampKey) }
    }
}
