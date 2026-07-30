import CoreImage
import Foundation
import Testing
@testable import Toruto

struct DefaultImageProcessorTests {
    private let processor = DefaultImageProcessor()

    private func makeImage(width: CGFloat, height: CGFloat) -> CIImage {
        CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
    }

    @Test
    func 中央フレーム80パーセントで切り出され原点がゼロになる() {
        let output = processor.process(
            makeImage(width: 4000, height: 3000),
            with: FilterParameters(),
            frameScale: 0.8
        )
        #expect(output.extent == CGRect(x: 0, y: 0, width: 1800, height: 2400))
    }

    @Test
    func フレームスケールに応じて切り出しサイズが変わる() {
        let output = processor.process(
            makeImage(width: 3000, height: 4000),
            with: FilterParameters(),
            frameScale: 0.5
        )
        #expect(output.extent == CGRect(x: 0, y: 0, width: 1500, height: 2000))
    }

    @Test
    func applyFiltersはCropせず全画角のまま返す() {
        let output = processor.applyFilters(to: makeImage(width: 3000, height: 4000), with: FilterParameters())
        #expect(output.extent == CGRect(x: 0, y: 0, width: 3000, height: 4000))
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

        let output = processor.process(makeImage(width: 3000, height: 4000), with: p, frameScale: 0.8)
        #expect(output.extent == CGRect(x: 0, y: 0, width: 2400, height: 3200))
    }

    @Test
    func makePhotoDataで保存用データを生成できる() throws {
        let output = processor.process(makeImage(width: 300, height: 400), with: FilterParameters(), frameScale: 0.8)
        let data = try #require(processor.makePhotoData(from: output))
        #expect(!data.isEmpty)
        // HEIC 非対応環境でも JPEG フォールバックで CIImage として読み戻せる
        #expect(CIImage(data: data) != nil)
    }

    @Test
    func stampDateで日付を焼き込んでもextentが変わらない() throws {
        let source = processor.process(makeImage(width: 300, height: 400), with: FilterParameters(), frameScale: 0.8)
        let stamped = processor.stampDate(Date(timeIntervalSince1970: 1_800_000_000), on: source)

        #expect(stamped.extent == source.extent)
        // 焼き込み後も描画可能であること
        #expect(processor.renderCGImage(from: stamped) != nil)
    }

    @Test
    func renderCGImageで実画像に変換できる() throws {
        let output = processor.process(makeImage(width: 300, height: 400), with: FilterParameters(), frameScale: 0.8)
        let cgImage = try #require(processor.renderCGImage(from: output))
        #expect(cgImage.width == 240)
        #expect(cgImage.height == 320)
    }
}
