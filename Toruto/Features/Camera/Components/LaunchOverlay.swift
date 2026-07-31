import SwiftUI

/// 起動画面（LaunchScreen.storyboard）から引き継いで表示するオーバーレイ。
///
/// 背景色・ロゴ・表示サイズを storyboard と一致させてあるため、
/// 起動画面からアプリ本体への切り替わりが視覚的に見えない。
/// カメラのプレビューが実際に届いてから退場するので、
/// 「オーバーレイは消えたのに映像はまだ真っ黒」という間が生まれない。
struct LaunchOverlay: View {
    /// storyboard の imageView と同じ表示サイズ
    static let logoWidth: CGFloat = 100
    static let logoHeight: CGFloat = 128

    /// プレビューが表示できる状態になったか
    let isReady: Bool
    /// 退場アニメーションまで終わったときに呼ばれる
    let onFinished: () -> Void

    /// カメラが応答しない場合でもここで必ず退場する
    private let timeout: Duration = .seconds(4)
    private let exitDuration: Double = 0.32

    @State private var isBreathing = false
    @State private var isFinishing = false

    var body: some View {
        ZStack {
            Color("LaunchBackground")

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: Self.logoWidth, height: Self.logoHeight)
                // 待機中の呼吸と退場のスケールは別モディファイアに分け、
                // repeatForever が退場アニメーションを引きずらないようにする
                .scaleEffect(isBreathing ? 1.04 : 1.0)
                .scaleEffect(isFinishing ? 1.14 : 1.0)
        }
        // storyboard は画面全体の中心にロゴを置くため、セーフエリアを無視して位置を合わせる
        .ignoresSafeArea()
        .opacity(isFinishing ? 0 : 1)
        // 退場中もカメラ UI を誤操作させない
        .allowsHitTesting(!isFinishing)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .onChange(of: isReady, initial: true) { _, ready in
            if ready { finish() }
        }
        .task {
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func finish() {
        guard !isFinishing else { return }
        withAnimation(.easeIn(duration: exitDuration)) {
            isFinishing = true
        } completion: {
            onFinished()
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        LaunchOverlay(isReady: false, onFinished: {})
    }
    .ignoresSafeArea()
}
