import SwiftUI

struct CountdownView: View {
    let step: Int
    let size: CGFloat

    var body: some View {
        Text("\(step)")
            .font(.system(size: size, weight: .thin, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Theme.text)
            .id(step)
            .transition(.scale(scale: 1.4).combined(with: .opacity))
    }
}
