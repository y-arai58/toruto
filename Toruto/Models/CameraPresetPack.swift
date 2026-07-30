/// カメラプリセットのパック（テーマ別セット）
struct CameraPresetPack: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let presets: [CameraPreset]
}
