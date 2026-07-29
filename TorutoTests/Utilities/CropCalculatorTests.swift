import CoreGraphics
import Testing
@testable import Toruto

struct CropCalculatorTests {
    private let aspect3x4: CGFloat = 3.0 / 4.0

    @Test
    func 横長の入力は高さ基準で中央を切り出す() {
        let rect = CropCalculator.centeredCropRect(
            in: CGRect(x: 0, y: 0, width: 4000, height: 3000),
            aspectRatio: aspect3x4
        )
        #expect(rect == CGRect(x: 875, y: 0, width: 2250, height: 3000))
    }

    @Test
    func ちょうど3対4の入力は全体が残る() {
        let rect = CropCalculator.centeredCropRect(
            in: CGRect(x: 0, y: 0, width: 3000, height: 4000),
            aspectRatio: aspect3x4
        )
        #expect(rect == CGRect(x: 0, y: 0, width: 3000, height: 4000))
    }

    @Test
    func 縦長すぎる入力は幅基準で中央を切り出す() {
        let rect = CropCalculator.centeredCropRect(
            in: CGRect(x: 0, y: 0, width: 3000, height: 6000),
            aspectRatio: aspect3x4
        )
        #expect(rect == CGRect(x: 0, y: 1000, width: 3000, height: 4000))
    }

    @Test
    func 原点がずれた入力でも中央基準で計算する() {
        let rect = CropCalculator.centeredCropRect(
            in: CGRect(x: 100, y: 200, width: 400, height: 400),
            aspectRatio: aspect3x4
        )
        #expect(rect == CGRect(x: 150, y: 200, width: 300, height: 400))
    }

    @Test
    func 不正な入力は空の矩形を返す() {
        #expect(CropCalculator.centeredCropRect(in: .zero, aspectRatio: aspect3x4) == .zero)
        #expect(CropCalculator.centeredCropRect(
            in: CGRect(x: 0, y: 0, width: 100, height: 100),
            aspectRatio: 0
        ) == .zero)
    }
}
