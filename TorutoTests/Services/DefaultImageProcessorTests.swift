import CoreImage
import Testing
@testable import Toruto

struct DefaultImageProcessorTests {
    private let processor = DefaultImageProcessor()

    private func makeImage(width: CGFloat, height: CGFloat) -> CIImage {
        CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
    }

    @Test
    func 横長の入力が3対4に切り出され原点がゼロになる() {
        let output = processor.process(makeImage(width: 4000, height: 3000), with: FilterParameters())
        #expect(output.extent == CGRect(x: 0, y: 0, width: 2250, height: 3000))
    }

    @Test
    func 全パラメータ適用でもextentが変わらない() {
        var p = FilterParameters()
        p.brightness = 0.05
        p.contrast = 1.2
        p.saturation = 0.8
        p.temperature = 5600
        p.tint = 5
        p.vignetteIntensity = 0.8
        p.vignetteRadius = 1.5
        p.grainIntensity = 0.6
        p.bloomIntensity = 0.5
        p.bloomRadius = 10
        p.blurRadius = 2

        let output = processor.process(makeImage(width: 3000, height: 4000), with: p)
        #expect(output.extent == CGRect(x: 0, y: 0, width: 3000, height: 4000))
    }

    @Test
    func makePhotoDataで保存用データを生成できる() throws {
        let output = processor.process(makeImage(width: 300, height: 400), with: FilterParameters())
        let data = try #require(processor.makePhotoData(from: output))
        #expect(!data.isEmpty)
        // HEIC 非対応環境でも JPEG フォールバックで CIImage として読み戻せる
        #expect(CIImage(data: data) != nil)
    }

    @Test
    func renderCGImageで実画像に変換できる() throws {
        let output = processor.process(makeImage(width: 300, height: 400), with: FilterParameters())
        let cgImage = try #require(processor.renderCGImage(from: output))
        #expect(cgImage.width == 300)
        #expect(cgImage.height == 400)
    }
}
