import SwiftUI

/// Slowly drifting stars used on the listening view. Cheap to render —
/// the stars are static dots arranged on init; the whole layer pans on
/// a long, slow loop. No timers, no per-frame updates.
struct StarFieldView: View {
    let starCount: Int
    private let stars: [Star]

    init(seed: UInt64 = 42, starCount: Int = 90) {
        self.starCount = starCount
        var rng = SeededRandom(seed: seed)
        self.stars = (0..<starCount).map { _ in
            Star(
                x: Double(rng.next() % 1000) / 1000.0,
                y: Double(rng.next() % 1000) / 1000.0,
                size: 0.8 + Double(rng.next() % 200) / 100.0,
                brightness: 0.25 + Double(rng.next() % 750) / 1000.0
            )
        }
    }

    @State private var drift: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(stars.indices, id: \.self) { i in
                    let s = stars[i]
                    Circle()
                        .fill(Color.white.opacity(s.brightness))
                        .frame(width: s.size, height: s.size)
                        .position(x: s.x * geo.size.width,
                                  y: s.y * geo.size.height + drift)
                        .blur(radius: s.size > 2 ? 0.5 : 0)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 120).repeatForever(autoreverses: true)) {
                    drift = 12
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private struct Star {
        let x: Double, y: Double, size: Double, brightness: Double
    }
}
