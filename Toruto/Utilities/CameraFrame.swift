import CoreGraphics

/// 中央フレーム（保存される領域）の定義。
/// プレビューは全画角を表示し、この領域の外側を暗く見せる（Dazz Cam 方式）
enum CameraFrame {
    /// フレームの比率（幅:高さ = 3:4 固定）
    static let aspectRatio: CGFloat = 3.0 / 4.0
    /// 視野に対するフレームの大きさ（全画角の 80%）
    static let scale: CGFloat = 0.8

    /// 表示サイズ内での保存フレームの矩形を返す（UI オーバーレイ用）
    static func rect(in size: CGSize) -> CGRect {
        CropCalculator.centeredCropRect(
            in: CGRect(origin: .zero, size: size),
            aspectRatio: aspectRatio,
            scale: scale
        )
    }
}
