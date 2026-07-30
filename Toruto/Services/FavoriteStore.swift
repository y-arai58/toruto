import Foundation

/// プリセットのお気に入り登録の永続化を担う
protocol FavoriteStore: AnyObject {
    func favoriteIDs() -> Set<String>
    func setFavorite(_ presetID: String, isFavorite: Bool)
}

/// UserDefaults による標準実装
final class UserDefaultsFavoriteStore: FavoriteStore {
    private static let key = "favoritePresetIDs"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func favoriteIDs() -> Set<String> {
        Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func setFavorite(_ presetID: String, isFavorite: Bool) {
        var ids = favoriteIDs()
        if isFavorite {
            ids.insert(presetID)
        } else {
            ids.remove(presetID)
        }
        defaults.set(ids.sorted(), forKey: Self.key)
    }
}
