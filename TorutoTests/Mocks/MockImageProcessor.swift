import CoreGraphics
import CoreImage
import Foundation
@testable import Toruto

final class MockImageProcessor: ImageProcessor, @unchecked Sendable {
    private(set) var processCallCount = 0
    private(set) var stampDateCallCount = 0
    private(set) var lastParameters: FilterParameters?

    private(set) var lastFrameScale: CGFloat?
    /// process に渡された画像の extent（向き補正の検証に使う）
    private(set) var lastProcessExtent: CGRect?

    func process(_ image: CIImage, with parameters: FilterParameters, frameScale: CGFloat) -> CIImage {
        processCallCount += 1
        lastParameters = parameters
        lastFrameScale = frameScale
        lastProcessExtent = image.extent
        return image
    }

    func applyFilters(to image: CIImage, with parameters: FilterParameters) -> CIImage {
        applyFiltersCallCount += 1
        lastParameters = parameters
        return image
    }

    private(set) var applyFiltersCallCount = 0

    func makePhotoData(from image: CIImage) -> Data? {
        Data([0x01])
    }

    func stampDate(_ date: Date, on image: CIImage) -> CIImage {
        stampDateCallCount += 1
        return image
    }

    func renderCGImage(from image: CIImage) -> CGImage? {
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        return context?.makeImage()
    }
}
