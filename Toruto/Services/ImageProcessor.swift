import CoreImage

/// 中央フレーム Crop + CIFilter チェーンの適用を担う
protocol ImageProcessor: AnyObject, Sendable {
    /// 中央 3:4 Crop → フィルターチェーンを適用した CIImage を返す
    func process(_ image: CIImage, with parameters: FilterParameters) -> CIImage
    /// 保存・表示用に CGImage へ変換する
    func renderCGImage(from image: CIImage) -> CGImage?
}
