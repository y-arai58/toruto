import AVFoundation
import CoreGraphics
import ImageIO

/// センサーから届いたバッファを、縦持ちの表示向きへ揃えるための向きを決める。
///
/// `AVCaptureConnection` への `videoRotationAngle` / `isVideoMirrored` の設定は、
/// 入力を張り替えた直後だと**エラーも警告もなく適用されない**ことがある。
/// その結果「設定したつもりの値」と「実際にバッファへ適用された値」がずれる。
///
/// 実際に前面カメラでは、初回構成（背面）で設定した 90 度が接続に残ったままバッファが届き、
/// そこへソフト側でもう 90 度足して二重回転していた（TASK-019 → TASK-024 → TASK-025）。
///
/// そのため設定値は一切あてにせず、**接続から読み戻した実測値**を基準に
/// 「あとどれだけ回す / 反転するか」だけを計算する。
/// 接続への設定が効いても効かなくても、最終的な表示向きは同じになる。
///
/// アプリは縦持ち固定（`UISupportedInterfaceOrientations = Portrait`）なので、
/// 端末の向きは考慮しない。
enum CameraOrientation {
    /// 縦持ち表示に必要な、センサー生バッファからの合計回転角（度）
    static let portraitRotation: CGFloat = 90

    /// 接続側で既に適用された変換を差し引いた、残りの向き。
    ///
    /// - Parameters:
    ///   - appliedRotation: 接続から読み戻した `videoRotationAngle`
    ///   - appliedMirroring: 接続から読み戻した `isVideoMirrored`
    ///   - mirrored: 最終的に鏡像にしたいか（プレビューは true、保存画像は false）
    static func remaining(
        appliedRotation: CGFloat,
        appliedMirroring: Bool,
        mirrored: Bool
    ) -> CGImagePropertyOrientation {
        let rotation = normalized(portraitRotation - appliedRotation)
        let needsMirroring = mirrored != appliedMirroring

        switch (Int(rotation.rounded()), needsMirroring) {
        case (90, false): return .right
        case (90, true): return .leftMirrored
        case (180, false): return .down
        case (180, true): return .downMirrored
        case (270, false): return .left
        case (270, true): return .rightMirrored
        default: return needsMirroring ? .upMirrored : .up
        }
    }

    /// プレビュー用。**届いたバッファの形**から必要な向きを決める。
    ///
    /// `AVCaptureVideoDataOutput` の接続が返す `videoRotationAngle` は、
    /// 前面カメラでは実際にバッファへ起きたことと一致しない。
    /// 接続が「回転 0」と言っているのにバッファはすでに縦向きで届き、
    /// そこへ 90 度足して横向きに倒していた（TASK-024）。
    ///
    /// 同じ計算を `AVCapturePhotoOutput` の接続に対して行ったときは正しく動いたため、
    /// 食い違うのは映像データ出力側だけと判断した。
    /// そこで回転量はプロパティではなく、バッファが横長か縦長かという観測から決める。
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

    /// 0 以上 360 未満に丸める
    private static func normalized(_ angle: CGFloat) -> CGFloat {
        let wrapped = angle.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }
}
