import SwiftUI

/// Anel que se desfaz: `progress` 1.0 = círculo inteiro, 0.0 = nada.
struct RingView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)   // o arco recua no sentido horário até o topo
        }
    }
}
