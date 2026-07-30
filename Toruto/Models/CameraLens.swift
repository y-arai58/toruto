/// 背面カメラのレンズ種別
enum CameraLens: String, CaseIterable, Codable {
    case ultraWide
    case wide
    case telephoto

    var displayName: String {
        switch self {
        case .ultraWide: "0.5x"
        case .wide: "1x"
        case .telephoto: "2x"
        }
    }
}
