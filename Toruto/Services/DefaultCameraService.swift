import AVFoundation
import CoreImage

/// AVCaptureSession を用いた CameraService の標準実装。
/// セッション操作はすべて sessionQueue 上で行う。
/// 可変状態は sessionQueue / continuationsLock で保護しているため @unchecked Sendable とする。
final class DefaultCameraService: NSObject, CameraService, @unchecked Sendable {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.thirdscope.toruto.camera.session")
    private let videoQueue = DispatchQueue(label: "com.thirdscope.toruto.camera.video")
    private var isConfigured = false
    private var position: AVCaptureDevice.Position = .back
    private var currentInput: AVCaptureDeviceInput?
    private var exposureBias: Float = 0

    private let continuationsLock = NSLock()
    private var frameContinuations: [UUID: AsyncStream<CIImage>.Continuation] = [:]

    /// 撮影完了まで delegate を保持する（キーは AVCapturePhotoSettings.uniqueID）
    private var inFlightCaptures: [Int64: PhotoCaptureDelegate] = [:]

    func makePreviewStream() -> AsyncStream<CIImage> {
        AsyncStream { continuation in
            let id = UUID()
            continuationsLock.lock()
            frameContinuations[id] = continuation
            continuationsLock.unlock()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.continuationsLock.lock()
                self.frameContinuations[id] = nil
                self.continuationsLock.unlock()
            }
        }
    }

    func requestAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func start() async throws {
        guard await requestAuthorization() else {
            throw CameraServiceError.permissionDenied
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try self.configureSessionIfNeeded()
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stop() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                if self.session.isRunning {
                    self.session.stopRunning()
                }
                continuation.resume()
            }
        }
    }

    func switchCamera() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try self.reconfigureInput(to: self.position == .back ? .front : .back)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func setExposureBias(_ bias: Float) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    self.exposureBias = bias
                    try self.applyExposureBias()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            sessionQueue.async {
                guard self.session.isRunning else {
                    continuation.resume(throwing: CameraServiceError.captureFailed)
                    return
                }
                let settings = AVCapturePhotoSettings()
                let uniqueID = settings.uniqueID
                let delegate = PhotoCaptureDelegate { [weak self] result in
                    continuation.resume(with: result)
                    self?.sessionQueue.async {
                        self?.inFlightCaptures[uniqueID] = nil
                    }
                }
                self.inFlightCaptures[uniqueID] = delegate
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    /// sessionQueue 上で呼ぶこと
    private func configureSessionIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            throw CameraServiceError.deviceUnavailable
        }
        session.addInput(input)
        currentInput = input

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(videoOutput), session.canAddOutput(photoOutput) else {
            throw CameraServiceError.configurationFailed
        }
        session.addOutput(videoOutput)
        session.addOutput(photoOutput)

        updateConnections()
        isConfigured = true
    }

    /// sessionQueue 上で呼ぶこと。入力を指定位置のカメラへ付け替える
    private func reconfigureInput(to newPosition: AVCaptureDevice.Position) throws {
        guard isConfigured else { throw CameraServiceError.configurationFailed }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if let currentInput {
            session.removeInput(currentInput)
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            // 失敗時は元の入力に戻す
            if let currentInput, session.canAddInput(currentInput) {
                session.addInput(currentInput)
                updateConnections()
            }
            throw CameraServiceError.deviceUnavailable
        }
        session.addInput(input)
        currentInput = input
        position = newPosition
        updateConnections()
        // 切替後も露出補正を維持する
        try? applyExposureBias()
    }

    /// sessionQueue 上で呼ぶこと。現在の入力デバイスに露出補正を適用する
    private func applyExposureBias() throws {
        guard let device = currentInput?.device else {
            throw CameraServiceError.configurationFailed
        }
        let clamped = min(max(exposureBias, device.minExposureTargetBias), device.maxExposureTargetBias)
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.setExposureTargetBias(clamped)
        } catch {
            throw CameraServiceError.configurationFailed
        }
    }

    /// sessionQueue 上で呼ぶこと。ポートレート固定 + 前面カメラはミラー表示
    private func updateConnections() {
        for connection in [videoOutput.connection(with: .video), photoOutput.connection(with: .video)] {
            guard let connection else { continue }
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = (position == .front)
            }
        }
    }
}

extension DefaultCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        continuationsLock.lock()
        let continuations = Array(frameContinuations.values)
        continuationsLock.unlock()
        for continuation in continuations {
            continuation.yield(image)
        }
    }
}

/// 1 回の撮影の完了を受け取る delegate
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<Data, Error>) -> Void

    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            completion(.failure(error))
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(CameraServiceError.captureFailed))
            return
        }
        completion(.success(data))
    }
}
