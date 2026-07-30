import SwiftUI

/// カスタムプリセットの微調整エディタ。
/// ハーフシートで表示し、背後のプレビューへ調整値をライブ反映する
struct CustomPresetEditorView: View {
    let initialDraft: CameraViewModel.PresetDraft
    let onChange: (FilterParameters) -> Void
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var parameters: FilterParameters

    init(
        initialDraft: CameraViewModel.PresetDraft,
        onChange: @escaping (FilterParameters) -> Void,
        onSave: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialDraft = initialDraft
        self.onChange = onChange
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: initialDraft.name)
        _parameters = State(initialValue: initialDraft.parameters)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("キャンセル") { onCancel() }
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button("保存") { onSave(name) }
                    .fontWeight(.semibold)
            }

            TextField("プリセット名", text: $name)
                .textFieldStyle(.roundedBorder)

            parameterSlider("彩度", value: $parameters.saturation, in: 0.5...1.5)
            parameterSlider("色温度", value: $parameters.temperature, in: 4000...9000)
            parameterSlider("グレイン", value: $parameters.grainIntensity, in: 0...1)
            parameterSlider("ビネット", value: $parameters.vignetteIntensity, in: 0...1.5)
        }
        .padding(20)
        .presentationDetents([.height(340)])
        .presentationBackground(.black.opacity(0.85))
        .presentationBackgroundInteraction(.disabled)
        .preferredColorScheme(.dark)
        .onChange(of: parameters) { _, newValue in
            onChange(newValue)
        }
    }

    private func parameterSlider(
        _ title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 56, alignment: .leading)
            Slider(value: value, in: range)
                .tint(.white)
        }
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        CustomPresetEditorView(
            initialDraft: .init(name: "CCD +", parameters: FilterParameters()),
            onChange: { _ in },
            onSave: { _ in },
            onCancel: {}
        )
    }
}
