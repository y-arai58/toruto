import SwiftUI

struct CameraView: View {
    @State private var viewModel: CameraViewModel
    @State private var isFlashing = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @MainActor
    init(viewModel: CameraViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? CameraViewModel())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Text(viewModel.currentPreset?.displayName ?? "Toruto")
                    .font(.headline)
                    .foregroundStyle(.white)

                previewFrame

                saveErrorBanner

                PresetSelector(
                    presets: viewModel.presets,
                    currentPreset: viewModel.currentPreset,
                    onSelect: { viewModel.selectPreset($0) }
                )

                bottomBar
            }
            .padding(.vertical, 16)
        }
        .task {
            await viewModel.startSession()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { await viewModel.startSession() }
            case .background:
                Task { await viewModel.stopSession() }
            default:
                break
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isFlashing) { _, newValue in
            newValue
        }
        .sensoryFeedback(.selection, trigger: viewModel.currentPreset?.id)
    }

    /// 中央フレーム（3:4 固定）。保存領域＝プレビュー領域として明示する
    private var previewFrame: some View {
        ZStack {
            CameraPreviewView(makeFrames: viewModel.makePreviewStream)

            statusOverlay

            Color.white
                .opacity(isFlashing ? 0.8 : 0)
                .allowsHitTesting(false)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        switch viewModel.status {
        case .permissionDenied:
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.6))
                Text("カメラへのアクセスが許可されていません")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
        case .unavailable:
            Text("カメラを利用できません")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        case .idle, .running:
            EmptyView()
        }
    }

    @ViewBuilder
    private var saveErrorBanner: some View {
        switch viewModel.saveError {
        case .permissionDenied:
            HStack(spacing: 8) {
                Text("保存には写真へのアクセス許可が必要です")
                    .font(.caption)
                    .foregroundStyle(.white)
                Button("設定") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.15), in: Capsule())
        case .failed:
            Text("保存に失敗しました")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        case nil:
            EmptyView()
        }
    }

    private var bottomBar: some View {
        HStack {
            capturedThumbnail
                .frame(width: 48, height: 48)

            Spacer()

            ShutterButton(isEnabled: viewModel.status == .running && !viewModel.isCapturing) {
                capture()
            }

            Spacer()

            // 前面/背面切替の予約スペース（Phase 1 後半で実装）
            Color.clear
                .frame(width: 48, height: 48)
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var capturedThumbnail: some View {
        if let image = viewModel.lastCapturedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.scale.combined(with: .opacity))
        } else {
            Color.clear
        }
    }

    private func capture() {
        withAnimation(.easeOut(duration: 0.08)) {
            isFlashing = true
        }
        Task {
            await viewModel.capturePhoto()
            withAnimation(.easeIn(duration: 0.2)) {
                isFlashing = false
            }
        }
    }
}

#Preview {
    CameraView()
}
