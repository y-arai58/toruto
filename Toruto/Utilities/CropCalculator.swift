import CoreGraphics

enum CropCalculator {
    /// extent の中央から aspectRatio（幅/高さ）の最大矩形 × scale を切り出す
    static func centeredCropRect(in extent: CGRect, aspectRatio: CGFloat, scale: CGFloat = 1) -> CGRect {
        guard extent.width > 0, extent.height > 0, aspectRatio > 0, scale > 0, scale <= 1 else {
            return .zero
        }

        var width = extent.width
        var height = width / aspectRatio
        if height > extent.height {
            height = extent.height
            width = height * aspectRatio
        }
        width *= scale
        height *= scale
        return CGRect(
            x: extent.midX - width / 2,
            y: extent.midY - height / 2,
            width: width,
            height: height
        )
    }
}
