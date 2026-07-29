import SwiftUI

struct CameraView: View {
    @State private var viewModel: CameraViewModel
    @State private var isFlashing = false
    @State private var isExposureVisible = false
    @State private var exposureValue = 0.0
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

                if isExposureVisible {
                    exposureSlider
                }

                PresetSelector(
                    presets: viewModel.presets,
                    currentPreset: viewModel.currentPreset,
                    isFavorite: { viewModel.isFavorite($0) },
                    onSelect: { viewModel.selectPreset($0) },
                    onToggleFavorite: { viewModel.toggleFavorite($0) }
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
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.favoritePresetIDs)
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
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
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

    private var exposureSlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "sun.min")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Slider(value: $exposureValue, in: CameraViewModel.exposureRange)
                .tint(.white)
                .onChange(of: exposureValue) { _, value in
                    Task { await viewModel.adjustExposure(value) }
                }
            Image(systemName: "sun.max")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(String(format: "%+.1f", exposureValue))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .transition(.opacity)
        .accessibilityLabel("露出補正")
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

    /// シャッターは ZStack で常に画面中央に固定する
    private var bottomBar: some View {
        ZStack {
            HStack(spacing: 16) {
                capturedThumbnail
                    .frame(width: 48, height: 48)

                exposureToggleButton

                Spacer()

                switchCameraButton
            }

            ShutterButton(isEnabled: viewModel.status == .running && !viewModel.isCapturing) {
                capture()
            }
        }
        .padding(.horizontal, 32)
    }

    private var exposureToggleButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                isExposureVisible.toggle()
            }
        } label: {
            Image(systemName: isExposureVisible ? "sun.max.fill" : "sun.max")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(isExposureVisible ? 0.25 : 0.12), in: Circle())
        }
        .accessibilityLabel("露出補正を表示")
    }

    private var switchCameraButton: some View {
        Button {
            Task { await viewModel.switchCamera() }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath.camera")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.12), in: Circle())
        }
        .disabled(viewModel.status != .running || viewModel.isSwitchingCamera)
        .opacity(viewModel.status == .running ? 1 : 0.4)
        .accessibilityLabel("カメラを切り替え")
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
