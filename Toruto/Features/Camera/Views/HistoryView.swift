import SwiftUI

/// Toruto アルバムの撮影履歴をグリッド表示するシート
struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    @MainActor
    init(viewModel: HistoryViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? HistoryViewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("撮影履歴")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") { dismiss() }
                    }
                }
                .background(Color.black)
                .preferredColorScheme(.dark)
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            if viewModel.items.isEmpty {
                emptyState
            } else {
                grid
            }
        case .permissionDenied:
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.6))
                Text("履歴の表示には写真へのアクセス許可が必要です")
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            Text("履歴を読み込めませんでした")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.items) { item in
                    Image(uiImage: item.image)
                        .resizable()
                        .aspectRatio(3 / 4, contentMode: .fill)
                        .clipped()
                }
            }
            .padding(2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.5))
            Text("まだ撮影した写真がありません")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryView()
}
