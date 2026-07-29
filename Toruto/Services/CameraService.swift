import CoreImage

/// カメラ操作で発生するエラー
enum CameraServiceError: Error {
    case permissionDenied
    case deviceUnavailable
    case configurationFailed
    case captureFailed
}

/// AVCaptureSession の管理・プレビューフレーム供給・静止画撮影を担う
protocol CameraService: AnyObject {
    /// プレビュー用フレームのストリームを生成する（呼び出しごとに新しいストリームを返す）
    func makePreviewStream() -> AsyncStream<CIImage>
    /// カメラ権限を確認し、未決定ならリクエストする
    func requestAuthorization() async -> Bool
    /// セッションを構成して起動する
    func start() async throws
    /// セッションを停止する
    func stop() async
    /// 静止画を撮影し、画像データを返す
    func capturePhoto() async throws -> Data
}
