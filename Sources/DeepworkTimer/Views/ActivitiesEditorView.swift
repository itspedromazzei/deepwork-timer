import SwiftUI
import DeepworkCore

struct ActivitiesEditorView: View {
    @Bindable var model: AppModel
    var ui: UIState
    @State private var newName = ""
    @FocusState private var newFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(model.settings.activities.enumerated()), id: \.element.id) { index, activity in
                row(index: index, activity: activity)
            }
            HStack(spacing: 8) {
                TextField(Strings.newActivity, text: $newName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.control))
                    .focused($newFieldFocused)
                    .onSubmit(add)
                Button(action: add) { Image(systemName: "plus") }
                    .buttonStyle(IconButtonStyle())
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 6)
        }
        .onAppear { newFieldFocused = model.settings.activities.isEmpty }
    }

    private func row(index: Int, activity: Activity) -> some View {
        let name = Binding(
            get: { activity.name },
            set: { model.renameActivity(activity.id, to: $0) }
        )
        return HStack(spacing: 8) {
            Button {
                var a = model.settings.activities[index]
                a.colorIndex = (a.colorIndex + 1) % Activity.paletteSize
                model.settings.activities[index] = a
            } label: {
                Circle().fill(Theme.activityColor(activity.colorIndex)).frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .help("Trocar cor")
            TextField("Nome", text: name)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.control))
            Button { model.moveActivity(from: index, to: index - 1) } label: { Image(systemName: "chevron.up") }
                .buttonStyle(IconButtonStyle())
                .disabled(index == 0)
            Button { model.moveActivity(from: index, to: index + 2) } label: { Image(systemName: "chevron.down") }
                .buttonStyle(IconButtonStyle())
                .disabled(index == model.settings.activities.count - 1)
            Button {
                model.removeActivity(activity.id)
                if ui.selectedActivityID == activity.id { ui.selectedActivityID = model.settings.lastActivity?.id }
            } label: { Image(systemName: "trash") }
                .buttonStyle(IconButtonStyle())
                .help("Remover (o histórico mantém o nome)")
        }
    }

    private func add() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let a = model.addActivity(named: trimmed)
        if ui.selectedActivityID == nil { ui.selectedActivityID = a.id }
        newName = ""
        newFieldFocused = true
    }
}
