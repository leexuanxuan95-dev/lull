import SwiftUI

enum LullColors {
    // Per UI.md palette.
    static let midnight  = Color(red: 0.058, green: 0.078, blue: 0.161)  // #0F1429
    static let nightDeep = Color(red: 0.035, green: 0.047, blue: 0.106)  // a touch darker
    static let nightSoft = Color(red: 0.110, green: 0.137, blue: 0.235)  // for cards over midnight
    static let moonCream = Color(red: 0.957, green: 0.941, blue: 0.910)  // #F4F0E8
    static let warmLamp  = Color(red: 0.910, green: 0.753, blue: 0.529)  // #E8C087
    static let forest    = Color(red: 0.176, green: 0.290, blue: 0.243)  // #2D4A3E

    // Soft text colors that read well against midnight.
    static let textPrimary   = Color(red: 0.957, green: 0.941, blue: 0.910).opacity(0.94)
    static let textSecondary = Color(red: 0.957, green: 0.941, blue: 0.910).opacity(0.62)
    static let textMuted     = Color(red: 0.957, green: 0.941, blue: 0.910).opacity(0.40)
    static let hairline      = Color(red: 0.957, green: 0.941, blue: 0.910).opacity(0.10)
}
