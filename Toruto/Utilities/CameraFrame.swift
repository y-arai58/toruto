import CoreGraphics

/// 中央フレーム（保存される領域）の定義。
/// プレビューは全画角を表示し、この領域の外側を暗く見せる（Dazz Cam 方式）。
/// サイズはピンチで可変（中央固定・3:4 固定は不変）で、換算焦点距離として表示する。
/// 換算 mm = レンズ基準 mm ÷ フレームスケール
enum CameraFrame {
    /// フレームの比率（幅:高さ = 3:4 固定）
    static let aspectRatio: CGFloat = 3.0 / 4.0
    /// 視野に対するフレームの既定サイズ
    static let defaultScale: CGFloat = 0.8
    /// 換算焦点距離の上限（Dazz 同等）
    static let maxEquivalentFocalLength: CGFloat = 260

    /// レンズ基準 mm に応じたスケールの可変範囲（下限 = 260mm 相当）
    static func scaleRange(forBaseFocalLength base: CGFloat) -> ClosedRange<CGFloat> {
        (base / maxEquivalentFocalLength)...1.0
    }

    static func clampScale(_ scale: CGFloat, baseFocalLength base: CGFloat) -> CGFloat {
        let range = scaleRange(forBaseFocalLength: base)
        return min(max(scale, range.lowerBound), range.upperBound)
    }

    /// 換算焦点距離（表示用・整数 mm）
    static func equivalentFocalLength(baseFocalLength base: CGFloat, scale: CGFloat) -> Int {
        guard scale > 0 else { return Int(base) }
        return Int(min(base / scale, maxEquivalentFocalLength).rounded())
    }

    /// 表示サイズ内での保存フレームの矩形を返す（UI オーバーレイ用）
    static func rect(in size: CGSize, scale: CGFloat) -> CGRect {
        CropCalculator.centeredCropRect(
            in: CGRect(origin: .zero, size: size),
            aspectRatio: aspectRatio,
            scale: min(max(scale, 0.01), 1)
        )
    }
}
