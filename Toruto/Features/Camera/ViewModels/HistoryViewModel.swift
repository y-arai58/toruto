import Observation
import UIKit

@MainActor
@Observable
final class HistoryViewModel {
    enum Status: Equatable {
        case loading
        case loaded
        case permissionDenied
        case failed
    }

    struct Item: Identifiable {
        let id: Int
        let image: UIImage
    }

    private(set) var status: Status = .loading
    private(set) var items: [Item] = []

    private let photoLibraryService: any PhotoLibraryService
    private static let fetchLimit = 24

    init(photoLibraryService: (any PhotoLibraryService)? = nil) {
        self.photoLibraryService = photoLibraryService ?? DefaultPhotoLibraryService()
    }

    func load() async {
        status = .loading
        do {
            let dataList = try await photoLibraryService.loadRecentPhotoData(limit: Self.fetchLimit)
            items = dataList.enumerated().compactMap { index, data in
                UIImage(data: data).map { Item(id: index, image: $0) }
            }
            status = .loaded
        } catch PhotoLibraryError.permissionDenied {
            status = .permissionDenied
        } catch {
            status = .failed
        }
    }
}
