import AVFoundation
import CoreGraphics
import ImageIO

/// プレビューのフレームを縦持ちの表示向きへ揃えるための向きを決める。
///
/// `AVCaptureConnection` の `videoRotationAngle` / `isVideoMirrored` は、
/// 設定しても**エラーも警告もなく適用されない**ことがあり、
/// 読み戻した値も実際にバッファへ起きたことと一致しない。
/// TASK-019 → TASK-024 で、この値を信じた実装が 3 回とも実機で失敗した。
///
/// そこで回転量はプロパティから計算せず、
/// **届いたバッファが横長か縦長か**という観測だけで決める。
///
/// 写真は AVFoundation が EXIF に向きを書くのでここは通さない
/// （`CameraViewModel.processCapturedPhoto` で EXIF を適用する）。
///
/// アプリは縦持ち固定（`UISupportedInterfaceOrientations = Portrait`）なので、
/// 端末の向きは考慮しない。
enum CameraOrientation {
    /// 届いたバッファの形から必要な向きを決める。
    ///
    /// - Parameters:
    ///   - bufferExtent: 届いたバッファの範囲
    ///   - appliedMirroring: 接続から読み戻した `isVideoMirrored`
    ///   - mirrored: 最終的に鏡像にしたいか
    static func forPreview(
        bufferExtent: CGRect,
        appliedMirroring: Bool,
        mirrored: Bool
    ) -> CGImagePropertyOrientation {
        let isLandscape = bufferExtent.width > bufferExtent.height
        let needsMirroring = mirrored != appliedMirroring

        switch (isLandscape, needsMirroring) {
        case (true, false): return .right         // 横長 → 90 度回して縦にする
        case (true, true): return .leftMirrored   // 同上 + 左右反転
        case (false, false): return .up           // すでに縦向き → 回さない
        case (false, true): return .upMirrored    // 同上 + 左右反転
        }
    }
}
