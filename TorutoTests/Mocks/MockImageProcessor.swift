import CoreGraphics
import CoreImage
@testable import Toruto

final class MockImageProcessor: ImageProcessor, @unchecked Sendable {
    private(set) var processCallCount = 0
    private(set) var lastParameters: FilterParameters?

    func process(_ image: CIImage, with parameters: FilterParameters) -> CIImage {
        processCallCount += 1
        lastParameters = parameters
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
