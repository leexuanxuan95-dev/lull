import SwiftUI

/// UI.md asks for GT Sectra (titles), Lyon Italic (prose), Söhne (UI).
/// Those are licensed fonts we don't ship; we approximate with system
/// equivalents — `.serif` for display, `.serif` italic for prose, default
/// for chrome — and trust the design language to do the rest.
enum LullFonts {
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func prose(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func uiMono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}
