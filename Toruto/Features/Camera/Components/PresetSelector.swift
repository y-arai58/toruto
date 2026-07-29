import SwiftUI

/// 横スクロールでプリセットを 1 アクション切替するチップ列
struct PresetSelector: View {
    let presets: [CameraPreset]
    let currentPreset: CameraPreset?
    let onSelect: (CameraPreset) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets) { preset in
                        chip(for: preset)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: currentPreset?.id) { _, id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private func chip(for preset: CameraPreset) -> some View {
        let isSelected = preset.id == currentPreset?.id
        return Button {
            onSelect(preset)
        } label: {
            Text(preset.displayName)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(isSelected ? .white : .white.opacity(0.12))
                )
        }
        .id(preset.id)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        Color.black
        PresetSelector(
            presets: [
                CameraPreset(id: "ccd", displayName: "CCD", filterParameters: FilterParameters()),
                CameraPreset(id: "soft", displayName: "Soft", filterParameters: FilterParameters()),
            ],
            currentPreset: nil,
            onSelect: { _ in }
        )
    }
}
