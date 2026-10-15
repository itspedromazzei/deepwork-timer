import SwiftUI

enum Theme {
    static let background = Color(hex: 0x14161B)
    static let card = Color(hex: 0x1C1F26)
    static let cardBorder = Color.white.opacity(0.06)
    static let focus = Color(hex: 0xFF8A3D)
    static let breakColor = Color(hex: 0x3DD6C4)
    static let countdown = Color.white
    static let text = Color.white.opacity(0.92)
    static let secondary = Color.white.opacity(0.5)
    static let faint = Color.white.opacity(0.25)
    static let track = Color.white.opacity(0.08)
    static let control = Color.white.opacity(0.08)
    static let controlHover = Color.white.opacity(0.14)

    static let palette: [Color] = [
        Color(hex: 0xFF8A3D), Color(hex: 0x3DD6C4), Color(hex: 0x7C9CFF), Color(hex: 0xF25F7A),
        Color(hex: 0xC3E86B), Color(hex: 0xE2B55A), Color(hex: 0xB487F2), Color(hex: 0x6FD3FF),
    ]

    static func activityColor(_ index: Int) -> Color {
        palette[((index % palette.count) + palette.count) % palette.count]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Botão escuro com hover, sem o estilo de vidro padrão do macOS 26.
struct PillButtonStyle: ButtonStyle {
    var prominent = false
    var tint: Color = Theme.focus

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(prominent ? Color.black.opacity(0.85) : Theme.text)
            .background(
                Capsule().fill(prominent ? tint : Theme.control)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Capsule())
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.secondary)
            .frame(width: 28, height: 28)
            .background(Circle().fill(Theme.control))
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Circle())
    }
}

/// Cartão de overlay (configurações, histórico, atividades) sobre um fundo escurecido.
struct OverlayCard<Content: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(IconButtonStyle())
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 10)
                ScrollView {
                    content()
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
            }
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.cardBorder))
            )
            .padding(12)
        }
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
    }
}

struct DarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack {
                configuration.label
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text)
                Spacer()
                Capsule()
                    .fill(configuration.isOn ? Theme.focus : Theme.control)
                    .frame(width: 34, height: 20)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(.white).padding(2)
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
