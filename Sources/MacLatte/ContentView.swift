import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: KeepAwakeController

    var body: some View {
        VStack(spacing: 10) {
            statusCard
            presetCard
            customCard
            footer
        }
        .padding(14)
        .frame(width: 300)
    }

    private var statusCard: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: ringProgress)

                Image(systemName: controller.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 16))
                    .foregroundStyle(controller.isActive ? Color.accentColor : Color.secondary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text("Keep Awake")
                    .font(.system(size: 13, weight: .semibold))
                Text(controller.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { controller.isActive },
                set: { newValue in
                    newValue ? controller.beginIndefinite() : controller.stop()
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(10)
        .card()
    }

    private var ringProgress: Double {
        guard controller.isActive else { return 0 }
        if controller.isIndefinite { return 1 }
        return max(controller.progressFraction, 0.02)
    }

    private var presetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OR KEEP AWAKE FOR")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .kerning(0.4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(controller.presets) { preset in
                    Button(preset.label) {
                        controller.start(seconds: preset.seconds)
                    }
                    .buttonStyle(.bordered)
                    .tint(isCurrentPreset(preset) ? Color.accentColor : nil)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(10)
        .card()
    }

    private var customCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CUSTOM")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .kerning(0.4)
                Spacer()
                Text(customLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $controller.customMinutes, in: 5...480)
                .controlSize(.small)
            Button("Start Custom Timer") {
                controller.startCustom()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .card()
    }

    private var footer: some View {
        HStack {
            Toggle("Launch at Login", isOn: Binding(
                get: { controller.launchAtLoginEnabled },
                set: { _ in controller.toggleLaunchAtLogin() }
            ))
            .toggleStyle(.checkbox)
            .controlSize(.small)
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                controller.quit()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    private func isCurrentPreset(_ preset: TimerPreset) -> Bool {
        controller.isActive && !controller.isIndefinite
            && Int(controller.totalSeconds) == Int(preset.seconds)
    }

    private var customLabel: String {
        let minutes = Int(controller.customMinutes)
        guard minutes >= 60 else { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

private extension View {
    func card() -> some View {
        self.background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
