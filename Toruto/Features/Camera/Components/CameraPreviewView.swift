import MetalKit
import SwiftUI

/// MTKView + Metal バックの CIContext でプレビューフレームを描画する。
/// フレーム到着ごとに手動で draw を呼び、SwiftUI の再評価を経由しない。
struct CameraPreviewView: UIViewRepresentable {
    /// makeUIView 時に一度だけ呼ばれ、購読するストリームを生成する
    let makeFrames: () -> AsyncStream<CIImage>

    func makeCoordinator() -> Renderer {
        Renderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.backgroundColor = .black
        context.coordinator.attach(view: view, frames: makeFrames())
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    static func dismantleUIView(_ uiView: MTKView, coordinator: Renderer) {
        coordinator.detach()
    }

    final class Renderer: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        private let commandQueue: MTLCommandQueue?
        private let ciContext: CIContext?
        private var currentImage: CIImage?
        private var consumeTask: Task<Void, Never>?

        override init() {
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device?.makeCommandQueue()
            ciContext = device.map { CIContext(mtlDevice: $0) }
            super.init()
        }

        func attach(view: MTKView, frames: AsyncStream<CIImage>) {
            consumeTask?.cancel()
            consumeTask = Task { @MainActor [weak self, weak view] in
                for await image in frames {
                    guard let self, let view else { return }
                    self.currentImage = image
                    view.draw()
                }
            }
        }

        func detach() {
            consumeTask?.cancel()
            consumeTask = nil
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let image = currentImage,
                  let ciContext,
                  let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let drawable = view.currentDrawable else { return }

            let drawableSize = view.drawableSize
            guard drawableSize.width > 0, drawableSize.height > 0,
                  image.extent.width > 0, image.extent.height > 0 else { return }

            // アスペクトフィルで中央に合わせる
            let scale = max(
                drawableSize.width / image.extent.width,
                drawableSize.height / image.extent.height
            )
            let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            let origin = CGPoint(
                x: scaled.extent.midX - drawableSize.width / 2,
                y: scaled.extent.midY - drawableSize.height / 2
            )
            let centered = scaled.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))

            ciContext.render(
                centered,
                to: drawable.texture,
                commandBuffer: commandBuffer,
                bounds: CGRect(origin: .zero, size: drawableSize),
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

#Preview {
    CameraPreviewView(makeFrames: { AsyncStream { $0.finish() } })
        .background(.black)
}
