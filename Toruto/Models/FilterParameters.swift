/// プリセット 1 つ分のフィルターパラメータ。
/// ピュアな型として定義し、CIFilter への変換は ImageProcessor が行う。
/// JSON では変更したい項目だけを記述すればよい（未指定はニュートラル値）。
struct FilterParameters: Codable, Equatable {
    /// 明るさ（0 がニュートラル、-1〜1）
    var brightness: Double = 0
    /// コントラスト（1 がニュートラル）
    var contrast: Double = 1
    /// 彩度（1 がニュートラル）
    var saturation: Double = 1
    /// 色温度（ケルビン。6500 がニュートラル）
    var temperature: Double = 6500
    /// ティント（0 がニュートラル。正で緑、負でマゼンタ寄り）
    var tint: Double = 0
    /// 周辺減光の強さ（0 で無効）
    var vignetteIntensity: Double = 0
    /// 周辺減光の半径
    var vignetteRadius: Double = 1
    /// フィルムグレインの強さ（0 で無効、0〜1）
    var grainIntensity: Double = 0
    /// ハレーション（ブルーム）の強さ（0 で無効）
    var bloomIntensity: Double = 0
    /// ハレーションの半径
    var bloomRadius: Double = 10
    /// ソフトフォーカスのぼかし半径（0 で無効）
    var blurRadius: Double = 0

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = FilterParameters()
        brightness = try container.decodeIfPresent(Double.self, forKey: .brightness) ?? defaults.brightness
        contrast = try container.decodeIfPresent(Double.self, forKey: .contrast) ?? defaults.contrast
        saturation = try container.decodeIfPresent(Double.self, forKey: .saturation) ?? defaults.saturation
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? defaults.temperature
        tint = try container.decodeIfPresent(Double.self, forKey: .tint) ?? defaults.tint
        vignetteIntensity = try container.decodeIfPresent(Double.self, forKey: .vignetteIntensity) ?? defaults.vignetteIntensity
        vignetteRadius = try container.decodeIfPresent(Double.self, forKey: .vignetteRadius) ?? defaults.vignetteRadius
        grainIntensity = try container.decodeIfPresent(Double.self, forKey: .grainIntensity) ?? defaults.grainIntensity
        bloomIntensity = try container.decodeIfPresent(Double.self, forKey: .bloomIntensity) ?? defaults.bloomIntensity
        bloomRadius = try container.decodeIfPresent(Double.self, forKey: .bloomRadius) ?? defaults.bloomRadius
        blurRadius = try container.decodeIfPresent(Double.self, forKey: .blurRadius) ?? defaults.blurRadius
    }
}
