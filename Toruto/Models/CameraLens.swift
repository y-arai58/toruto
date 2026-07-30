/// 背面カメラのレンズ種別
enum CameraLens: String, CaseIterable, Codable {
    case ultraWide
    case wide
    case telephoto

    /// 35mm 判換算の基準焦点距離（0.5x = 13mm / 1x = 26mm / 2x = 52mm）
    var equivalentFocalLength: Double {
        switch self {
        case .ultraWide: 13
        case .wide: 26
        case .telephoto: 52
        }
    }

    var displayName: String {
        "\(Int(equivalentFocalLength))mm"
    }
}
