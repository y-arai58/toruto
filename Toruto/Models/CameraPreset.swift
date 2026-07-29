/// カメラプリセット =「カメラ本体」。切り替えるだけで撮影体験が変わる。
struct CameraPreset: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let filterParameters: FilterParameters
}
