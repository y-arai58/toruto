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
    /// プレビュー用フレームのストリームを生成する（呼び出しごとに新しいストリームを返す）。
    /// フレームは縦持ちの表示向きに補正済みで届く
    func makePreviewStream() -> AsyncStream<CIImage>
    /// カメラ権限を確認し、未決定ならリクエストする
    func requestAuthorization() async -> Bool
    /// セッションを構成して起動する
    func start() async throws
    /// セッションを停止する
    func stop() async
    /// 前面/背面カメラを切り替える（レンズは wide にリセットされる）
    func switchCamera() async throws
    /// 現在のカメラ位置で利用可能なレンズを返す（前面は wide のみ）
    func availableLenses() async -> [CameraLens]
    /// レンズを切り替える（背面のみ）
    func selectLens(_ lens: CameraLens) async throws
    /// 露出補正（EV）を設定する。デバイスの対応範囲にクランプされる
    func setExposureBias(_ bias: Float) async throws
    /// フラッシュの ON/OFF を設定する（非対応デバイスでは撮影時に無視される）
    func setFlashEnabled(_ isEnabled: Bool) async
    /// 静止画を撮影し、画像データを返す。
    /// 向きは AVFoundation が書いた EXIF に入っているため、読み出し側で適用する
    func capturePhoto() async throws -> Data
}
