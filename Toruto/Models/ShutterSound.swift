/// シャッター音の種類
enum ShutterSound: String, CaseIterable, Codable {
    case classic
    case digital
    case film

    var displayName: String {
        switch self {
        case .classic: "クラシック"
        case .digital: "デジタル"
        case .film: "フィルム"
        }
    }

    /// バンドル内の音源ファイル名（nil はシステム音を使う）
    var fileName: String? {
        switch self {
        case .classic: nil
        case .digital: "shutter_digital"
        case .film: "shutter_film"
        }
    }
}
