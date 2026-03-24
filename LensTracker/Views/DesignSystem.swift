import SwiftUI

enum LensPalette {
    static let ink = Color(red: 0.10, green: 0.16, blue: 0.19)
    static let slate = Color(red: 0.28, green: 0.36, blue: 0.41)
    static let mist = Color(red: 0.94, green: 0.95, blue: 0.92)
    static let sand = Color(red: 0.88, green: 0.82, blue: 0.70)
    static let teal = Color(red: 0.21, green: 0.56, blue: 0.56)
    static let coral = Color(red: 0.87, green: 0.42, blue: 0.35)
    static let gold = Color(red: 0.78, green: 0.60, blue: 0.28)
}

struct LensScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.94),
                    Color(red: 0.93, green: 0.94, blue: 0.91)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    LensPalette.sand.opacity(0.30),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 300
            )

            RadialGradient(
                colors: [
                    LensPalette.teal.opacity(0.18),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }
}

struct LensCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.75), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: LensPalette.ink.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}

struct LensHeroCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.88),
                        Color.white.opacity(0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: LensPalette.ink.opacity(0.10), radius: 28, x: 0, y: 14)
    }
}

struct LensSectionTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(LensPalette.teal)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(LensPalette.ink)
        }
    }
}

extension View {
    func lensCardStyle() -> some View {
        modifier(LensCardModifier())
    }

    func lensHeroCardStyle() -> some View {
        modifier(LensHeroCardModifier())
    }
}
