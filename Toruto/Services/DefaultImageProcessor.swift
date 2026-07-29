import CoreImage
import CoreImage.CIFilterBuiltins

/// Core Image による ImageProcessor の標準実装。
/// CIContext は生成コストが高いため 1 インスタンスで使い回す。
/// CIContext / CIFilter 生成はスレッドセーフなため @unchecked Sendable とする。
final class DefaultImageProcessor: ImageProcessor, @unchecked Sendable {
    /// 中央フレームの比率（幅:高さ = 3:4 固定）
    static let frameAspectRatio: CGFloat = 3.0 / 4.0

    private let ciContext: CIContext

    init(ciContext: CIContext = CIContext()) {
        self.ciContext = ciContext
    }

    func process(_ image: CIImage, with parameters: FilterParameters) -> CIImage {
        let cropped = cropToCenterFrame(image)
        return applyFilters(to: cropped, parameters: parameters)
    }

    func renderCGImage(from image: CIImage) -> CGImage? {
        ciContext.createCGImage(image, from: image.extent)
    }

    /// 中央 3:4 で切り出し、原点を (0, 0) に揃える
    private func cropToCenterFrame(_ image: CIImage) -> CIImage {
        let rect = CropCalculator.centeredCropRect(in: image.extent, aspectRatio: Self.frameAspectRatio)
        guard !rect.isEmpty else { return image }
        return image
            .cropped(to: rect)
            .transformed(by: CGAffineTransform(translationX: -rect.origin.x, y: -rect.origin.y))
    }

    private func applyFilters(to image: CIImage, parameters p: FilterParameters) -> CIImage {
        let extent = image.extent
        var result = image

        if p.brightness != 0 || p.contrast != 1 || p.saturation != 1 {
            let filter = CIFilter.colorControls()
            filter.inputImage = result
            filter.brightness = Float(p.brightness)
            filter.contrast = Float(p.contrast)
            filter.saturation = Float(p.saturation)
            result = filter.outputImage ?? result
        }

        if p.temperature != 6500 || p.tint != 0 {
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = result
            filter.neutral = CIVector(x: 6500, y: 0)
            filter.targetNeutral = CIVector(x: p.temperature, y: p.tint)
            result = filter.outputImage ?? result
        }

        if p.blurRadius > 0 {
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = result.clampedToExtent()
            filter.radius = Float(p.blurRadius)
            result = filter.outputImage?.cropped(to: extent) ?? result
        }

        if p.bloomIntensity > 0 {
            let filter = CIFilter.bloom()
            filter.inputImage = result.clampedToExtent()
            filter.intensity = Float(p.bloomIntensity)
            filter.radius = Float(p.bloomRadius)
            result = filter.outputImage?.cropped(to: extent) ?? result
        }

        if p.vignetteIntensity > 0 {
            let filter = CIFilter.vignette()
            filter.inputImage = result
            filter.intensity = Float(p.vignetteIntensity)
            filter.radius = Float(p.vignetteRadius)
            result = filter.outputImage ?? result
        }

        if p.grainIntensity > 0 {
            result = compositeGrain(over: result, intensity: p.grainIntensity, extent: extent)
        }

        return result.cropped(to: extent)
    }

    /// CIRandomGenerator のノイズをモノクロ化して重ねる
    private func compositeGrain(over image: CIImage, intensity: Double, extent: CGRect) -> CIImage {
        let noise = CIFilter.randomGenerator().outputImage?.cropped(to: extent)
        guard let noise else { return image }

        // 輝度ノイズのみを弱いアルファで重ねる
        let alpha = CGFloat(intensity) * 0.2
        let mono = noise.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: alpha),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        ])
        return mono.composited(over: image)
    }
}
