import AVFoundation
import ImageIO

/// センサーから届く生バッファを、縦持ちの表示向きへ揃えるための向き。
///
/// 向きの補正を `AVCaptureConnection` の `videoRotationAngle` / `isVideoMirrored` に
/// 任せると、入力を張り替えたときに設定が黙って適用されないことがある。
/// 実際 TASK-019 で「commit の後に設定する」修正を入れても前面カメラの横向きは直らず、
/// プレビュー・保存画像の両方が横向きのままだった。
///
/// そのため向きの補正は接続に任せず、常にここで決めた値をコード側で適用する。
/// アプリは縦持ち固定（`UISupportedInterfaceOrientations = Portrait`）なので、
/// 端末の向きは考慮しない。
enum CameraOrientation {
    /// 縦持ちでの表示向き。
    ///
    /// - 背面: 生バッファは横向きで届くため 90 度回して縦にする（`.right`）
    /// - 前面: 90 度回したうえで左右反転し、鏡と同じ見え方にする（`.leftMirrored`）
    ///
    /// 実機で前面が上下逆さまに見える場合は `.rightMirrored` に入れ替える
    /// （`.leftMirrored` と `.rightMirrored` は 180 度の違い）。
    /// 前面が鏡像になっていない（服の文字がそのまま読める）場合は `.right` に入れ替える。
    static func portrait(for position: AVCaptureDevice.Position) -> CGImagePropertyOrientation {
        position == .front ? .leftMirrored : .right
    }
}
