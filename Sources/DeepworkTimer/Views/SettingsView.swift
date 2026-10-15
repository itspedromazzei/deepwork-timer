import SwiftUI
import DeepworkCore

struct SettingsView: View {
    @Bindable var model: AppModel
    var ui: UIState
    let actions: AppActions

    private var focusMinutes: Binding<Double> {
        Binding(get: { Double(model.settings.focusMinutes) }, set: { model.settings.focusMinutes = Int($0) })
    }
    private var breakMinutes: Binding<Double> {
        Binding(get: { Double(model.settings.breakMinutes) }, set: { model.settings.breakMinutes = Int($0) })
    }
    private var displaySelection: Binding<UInt32?> {
        Binding(
            get: { model.settings.fullscreenDisplayID },
            set: { id in
                model.settings.fullscreenDisplayID = id
                model.settings.fullscreenDisplayName = ui.screens.first { $0.id == id }?.name
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Tempo")
            sliderRow(Strings.focusDuration, value: focusMinutes, range: 5...180, step: 5,
                      text: "\(model.settings.focusMinutes) \(Strings.minutes)")
            sliderRow(Strings.breakDuration, value: breakMinutes, range: 0...60, step: 1,
                      text: "\(model.settings.breakMinutes) \(Strings.minutes)")
            Toggle(Strings.autoStartBreak, isOn: $model.settings.autoStartBreak)
            Toggle(Strings.autoStartNextFocus, isOn: $model.settings.autoStartNextFocus)
            Toggle(Strings.countdownTicks, isOn: $model.settings.countdownTicks)
            Toggle(Strings.keepAwake, isOn: $model.settings.keepAwake)

            SectionLabel(Strings.focusSound)
            HStack {
                Text(Strings.focusSound).font(.system(size: 13)).foregroundStyle(Theme.text)
                Spacer()
                Picker("", selection: $model.settings.audioMode) {
                    ForEach(AudioMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
            }
            if model.settings.audioMode == .binauralBeta {
                sliderRow(Strings.beatFrequency, value: $model.settings.binauralBeatHz, range: 14...30, step: 1,
                          text: "\(Int(model.settings.binauralBeatHz)) Hz")
            }
            if model.settings.audioMode.isBinaural {
                Text(Strings.headphonesHint)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondary)
            }
            HStack(spacing: 10) {
                sliderRow(Strings.volume, value: $model.settings.audioVolume, range: 0...1, step: 0.01,
                          text: "\(Int(model.settings.audioVolume * 100))%")
                Button(ui.isPreviewingAudio ? Strings.stop : Strings.test) {
                    if ui.isPreviewingAudio { actions.stopPreview() } else { actions.previewAudio() }
                }
                .buttonStyle(PillButtonStyle())
            }
            Toggle(Strings.soundDuringBreak, isOn: $model.settings.audioDuringBreak)
            if let err = ui.audioError {
                Text(err).font(.system(size: 11)).foregroundStyle(Theme.focus)
            }

            SectionLabel("Sino")
            HStack(spacing: 10) {
                sliderRow(Strings.bellVolume, value: $model.settings.bellVolume, range: 0...1, step: 0.01,
                          text: "\(Int(model.settings.bellVolume * 100))%")
                Button(Strings.test, action: actions.previewBell)
                    .buttonStyle(PillButtonStyle())
            }

            SectionLabel("Janela")
            HStack {
                Text(Strings.coverDisplay).font(.system(size: 13)).foregroundStyle(Theme.text)
                Spacer()
                Picker("", selection: displaySelection) {
                    Text(Strings.automaticDisplay).tag(UInt32?.none)
                    ForEach(ui.screens) { s in
                        Text(s.name).tag(UInt32?.some(s.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
            }
            Button(ui.windowMode == .cover ? Strings.floatingMode : Strings.coverMode, action: actions.toggleWindowMode)
                .buttonStyle(PillButtonStyle())
            Text("Atalhos: Espaço inicia/pausa · Esc fecha ou sai da tela cheia · ⌘⇧F alterna o modo · ⌘. para · ⌘Y histórico · ⌘E atividades")
                .font(.system(size: 11))
                .foregroundStyle(Theme.faint)
                .padding(.top, 6)
        }
        .toggleStyle(DarkToggleStyle())
        .tint(Theme.focus)
        .onChange(of: model.settings.audioMode) { _, _ in actions.audioSettingsChanged() }
        .onChange(of: model.settings.audioVolume) { _, _ in actions.audioSettingsChanged() }
        .onChange(of: model.settings.binauralBeatHz) { _, _ in actions.audioSettingsChanged() }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 13)).foregroundStyle(Theme.text)
                Spacer()
                Text(text).font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.secondary)
            }
            Slider(value: value, in: range, step: step)
                .controlSize(.small)
        }
    }
}
