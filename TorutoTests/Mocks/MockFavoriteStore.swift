@testable import Toruto

final class MockFavoriteStore: FavoriteStore {
    private var ids: Set<String>

    init(favorites: Set<String> = []) {
        ids = favorites
    }

    func favoriteIDs() -> Set<String> {
        ids
    }

    func setFavorite(_ presetID: String, isFavorite: Bool) {
        if isFavorite {
            ids.insert(presetID)
        } else {
            ids.remove(presetID)
        }
    }
}
