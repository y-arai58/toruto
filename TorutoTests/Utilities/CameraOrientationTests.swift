import AVFoundation
import ImageIO
import Testing
@testable import Toruto

struct CameraOrientationTests {
    @Test
    func portrait_背面は90度回転のみ() {
        #expect(CameraOrientation.portrait(for: .back) == .right)
    }

    @Test
    func portrait_前面は回転に加えて左右反転する() {
        let front = CameraOrientation.portrait(for: .front)

        #expect(front == .leftMirrored)
        // 鏡像になっていること（反転なしの向きと同じにならない）
        #expect(front != CameraOrientation.portrait(for: .back))
    }

    @Test
    func portrait_位置が不明なときは背面と同じ扱いにする() {
        #expect(CameraOrientation.portrait(for: .unspecified) == .right)
    }
}
