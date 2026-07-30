import Testing
import UIKit
@testable import Toruto

@MainActor
struct HistoryViewModelTests {
    @Test
    func load_成功時は画像一覧を保持する() async {
        let service = MockPhotoLibraryService()
        service.loadResult = .success([Self.makeImageData(), Self.makeImageData()])
        let viewModel = HistoryViewModel(photoLibraryService: service)

        await viewModel.load()

        #expect(viewModel.status == .loaded)
        #expect(viewModel.items.count == 2)
    }

    @Test
    func load_画像でないデータは除外される() async {
        let service = MockPhotoLibraryService()
        service.loadResult = .success([Data([0x00]), Self.makeImageData()])
        let viewModel = HistoryViewModel(photoLibraryService: service)

        await viewModel.load()

        #expect(viewModel.status == .loaded)
        #expect(viewModel.items.count == 1)
    }

    @Test
    func load_権限拒否時はpermissionDeniedになる() async {
        let service = MockPhotoLibraryService()
        service.loadResult = .failure(PhotoLibraryError.permissionDenied)
        let viewModel = HistoryViewModel(photoLibraryService: service)

        await viewModel.load()

        #expect(viewModel.status == .permissionDenied)
        #expect(viewModel.items.isEmpty)
    }

    @Test
    func load_失敗時はfailedになる() async {
        let service = MockPhotoLibraryService()
        service.loadResult = .failure(PhotoLibraryError.loadFailed)
        let viewModel = HistoryViewModel(photoLibraryService: service)

        await viewModel.load()

        #expect(viewModel.status == .failed)
    }

    private static func makeImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        return renderer.pngData { context in
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }
}
