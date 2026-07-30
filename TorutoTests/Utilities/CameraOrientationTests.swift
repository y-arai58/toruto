import CoreGraphics
import ImageIO
import Testing
@testable import Toruto

struct CameraOrientationTests {
    // MARK: - 接続が何も適用していない（生の横向きバッファが届く）

    @Test
    func remaining_未回転のバッファは90度回す() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 0,
            appliedMirroring: false,
            mirrored: false
        )

        #expect(orientation == .right)
    }

    @Test
    func remaining_未回転で鏡像にしたいときは反転付きになる() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 0,
            appliedMirroring: false,
            mirrored: true
        )

        #expect(orientation == .leftMirrored)
    }

    // MARK: - 接続が既に回転を適用している（前面カメラで起きていたケース）

    @Test
    func remaining_接続が90度適用済みなら追加の回転はしない() {
        // ここで .right を返すと二重回転になり、プレビューが横向きになる
        let orientation = CameraOrientation.remaining(
            appliedRotation: 90,
            appliedMirroring: false,
            mirrored: false
        )

        #expect(orientation == .up)
    }

    @Test
    func remaining_接続が90度適用済みで鏡像にしたいときは反転のみ() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 90,
            appliedMirroring: false,
            mirrored: true
        )

        #expect(orientation == .upMirrored)
    }

    @Test
    func remaining_接続が既に鏡像なら二重に反転しない() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 90,
            appliedMirroring: true,
            mirrored: true
        )

        #expect(orientation == .up)
    }

    @Test
    func remaining_接続が鏡像だが鏡像にしたくないときは反転で打ち消す() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 90,
            appliedMirroring: true,
            mirrored: false
        )

        #expect(orientation == .upMirrored)
    }

    // MARK: - その他の回転角

    @Test
    func remaining_接続が180度適用済みなら270度戻す() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 180,
            appliedMirroring: false,
            mirrored: false
        )

        #expect(orientation == .left)
    }

    @Test
    func remaining_接続が270度適用済みなら180度回す() {
        let orientation = CameraOrientation.remaining(
            appliedRotation: 270,
            appliedMirroring: false,
            mirrored: false
        )

        #expect(orientation == .down)
    }

    // MARK: - プレビュー（届いたバッファの形から決める）

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

    @Test
    func remaining_360度は0度と同じ扱いになる() {
        #expect(
            CameraOrientation.remaining(appliedRotation: 360, appliedMirroring: false, mirrored: false)
                == CameraOrientation.remaining(appliedRotation: 0, appliedMirroring: false, mirrored: false)
        )
    }
}
