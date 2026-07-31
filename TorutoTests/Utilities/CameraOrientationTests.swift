import CoreGraphics
import ImageIO
import Testing
@testable import Toruto

struct CameraOrientationTests {
    @Test
    func forPreview_横長のバッファは90度回して縦にする() {
        let orientation = CameraOrientation.forPreview(
            bufferExtent: CGRect(x: 0, y: 0, width: 1920, height: 1440),
            appliedMirroring: false,
            mirrored: false
        )

        #expect(orientation == .right)
    }

    @Test
    func forPreview_横長で鏡像にしたいときは反転付きになる() {
        let orientation = CameraOrientation.forPreview(
            bufferExtent: CGRect(x: 0, y: 0, width: 1920, height: 1440),
            appliedMirroring: false,
            mirrored: true
        )

        #expect(orientation == .leftMirrored)
    }

    @Test
    func forPreview_すでに縦長なら回さない() {
        // 前面カメラで起きていたケース。ここで回すと横向きに倒れる
        let orientation = CameraOrientation.forPreview(
            bufferExtent: CGRect(x: 0, y: 0, width: 1440, height: 1920),
            appliedMirroring: false,
            mirrored: false
        )

        #expect(orientation == .up)
    }

    @Test
    func forPreview_すでに縦長で鏡像にしたいときは反転のみ() {
        let orientation = CameraOrientation.forPreview(
            bufferExtent: CGRect(x: 0, y: 0, width: 1440, height: 1920),
            appliedMirroring: false,
            mirrored: true
        )

        #expect(orientation == .upMirrored)
    }

    @Test
    func forPreview_接続が既に鏡像なら二重に反転しない() {
        let orientation = CameraOrientation.forPreview(
            bufferExtent: CGRect(x: 0, y: 0, width: 1440, height: 1920),
            appliedMirroring: true,
            mirrored: true
        )

        #expect(orientation == .up)
    }
}
