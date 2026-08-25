import AppKit
import SwiftUI

/// The six OS-style note themes. Defines the chrome (geometry, material, font,
/// caption, button placement). The note's *color* is a separate axis.
enum NoteTheme: String, Codable, CaseIterable, Identifiable {
    case windows7
    case windows8
    case windows10
    case windows11
    case ubuntu1404     // "Ubuntu Classic"
    case ubuntuModern
    // Raw values kept stable for persistence; display names changed.
    case osxMavericks   // "MacOS Classic"
    case macGlass       // "MacOS Modern"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .windows7:     return "Windows 7"
        case .windows8:     return "Windows 8"
        case .windows10:    return "Windows 10"
        case .windows11:    return "Windows 11"
        case .ubuntu1404:   return "Ubuntu Classic"
        case .ubuntuModern: return "Ubuntu Modern"
        case .osxMavericks: return "MacOS Classic"
        case .macGlass:     return "MacOS Modern"
        }
    }
}

/// The six standard note colors (orthogonal to theme). Each supplies a base
/// background, a caption tint, and a contrasting text color.
enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case yellow, blue, green, pink, purple, white

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue:   return "Blue"
        case .green:  return "Green"
        case .pink:   return "Pink"
        case .purple: return "Purple"
        case .white:  return "White"
        }
    }

    var palette: ColorPalette {
        switch self {
        case .yellow: return ColorPalette(background: .hex(0xFCF8B5), caption: .hex(0xF4EE9E), text: .hex(0x33312B))
        case .blue:   return ColorPalette(background: .hex(0xC5E3F6), caption: .hex(0xAFD6F0), text: .hex(0x2B3138))
        case .green:  return ColorPalette(background: .hex(0xCFEFA8), caption: .hex(0xBCE68F), text: .hex(0x2F3528))
        case .pink:   return ColorPalette(background: .hex(0xF9CEDF), caption: .hex(0xF4B8D0), text: .hex(0x3A2C32))
        case .purple: return ColorPalette(background: .hex(0xD9C8EC), caption: .hex(0xC9B3E6), text: .hex(0x322B3A))
        case .white:  return ColorPalette(background: .hex(0xF4F4F4), caption: .hex(0xE6E6E6), text: .hex(0x2B2B2B))
        }
    }
}

struct ColorPalette {
    let background: NSColor
    let caption: NSColor
    let text: NSColor
}

/// How a surface is painted.
enum BackgroundFill {
    case solid(NSColor)
    case gradient(top: NSColor, bottom: NSColor)
    case vibrancy(material: NSVisualEffectView.Material, tint: NSColor?, tintAlpha: CGFloat, effectAlpha: CGFloat)
}

struct ThemeBorder {
    let color: NSColor
    let width: CGFloat
}

/// The themed top caption bar holding the +/× buttons.
struct CaptionStyle {
    var height: CGFloat
    var fill: BackgroundFill
    var buttonSide: HorizontalEdge      // .leading = Ubuntu (Unity), .trailing = rest
    var controlColor: NSColor
    var hoverOnly: Bool                 // paper themes reveal buttons on hover
    var separator: NSColor? = nil       // optional 1px line under the caption
}

/// The full visual spec for a note = theme (chrome) × color (hue).
struct ThemeStyle {
    var body: BackgroundFill
    var textColor: NSColor
    var font: NSFont
    var cornerRadius: CGFloat
    var border: ThemeBorder?
    var caption: CaptionStyle
    var hoverAccent: NSColor

    private static func font(_ names: [String], _ size: CGFloat) -> NSFont {
        for name in names where NSFont(name: name, size: size) != nil {
            return NSFont(name: name, size: size)!
        }
        return NSFont.systemFont(ofSize: size)
    }

    static func style(for theme: NoteTheme, color: NoteColor = .yellow) -> ThemeStyle {
        let pal = color.palette

        switch theme {

        case .windows7:
            // Aero: colored paper, soft caption, hover buttons, small radius.
            return ThemeStyle(
                body: .solid(pal.background),
                textColor: pal.text,
                font: font(["Segoe Print", "Bradley Hand"], 15),
                cornerRadius: 5,
                border: ThemeBorder(color: .hex(0x000000, alpha: 0.10), width: 1),
                caption: CaptionStyle(height: 22, fill: .solid(pal.caption),
                                      buttonSide: .trailing,
                                      controlColor: pal.text.withAlphaComponent(0.6),
                                      hoverOnly: true),
                hoverAccent: .hex(0xC23B22))

        case .windows8:
            // Metro: flat, square corners, always-visible flat caption.
            return ThemeStyle(
                body: .solid(pal.background),
                textColor: pal.text,
                font: font(["Segoe UI", "Helvetica Neue"], 14),
                cornerRadius: 0,
                border: nil,
                caption: CaptionStyle(height: 24, fill: .solid(pal.caption),
                                      buttonSide: .trailing,
                                      controlColor: pal.text,
                                      hoverOnly: false),
                hoverAccent: .hex(0x1BA1E2))

        case .windows10:
            // Flat windowed: square corners, a thin border, and a blue accent
            // underline on the caption (the Win10 active-title cue).
            return ThemeStyle(
                body: .solid(pal.background),
                textColor: pal.text,
                font: font(["Segoe UI", "Helvetica Neue"], 14),
                cornerRadius: 0,
                border: ThemeBorder(color: .hex(0x000000, alpha: 0.25), width: 1),
                caption: CaptionStyle(height: 26, fill: .solid(pal.caption),
                                      buttonSide: .trailing,
                                      controlColor: pal.text,
                                      hoverOnly: false,
                                      separator: .hex(0x0078D7)),
                hoverAccent: .hex(0x0078D7))

        case .windows11:
            // Fluent Acrylic: blurred backdrop with a strong color tint (reads as
            // a colored note with frosted depth, not see-through).
            return ThemeStyle(
                body: .vibrancy(material: .underWindowBackground,
                                tint: pal.background, tintAlpha: 0.62, effectAlpha: 1.0),
                textColor: pal.text,
                font: font(["Segoe UI Variable Text", "Segoe UI", "Helvetica Neue"], 14),
                cornerRadius: 10,
                border: ThemeBorder(color: .hex(0xFFFFFF, alpha: 0.45), width: 1),
                caption: CaptionStyle(height: 28,
                                      fill: .vibrancy(material: .underWindowBackground,
                                                      tint: pal.caption, tintAlpha: 0.70, effectAlpha: 1.0),
                                      buttonSide: .trailing,
                                      controlColor: pal.text.withAlphaComponent(0.75),
                                      hoverOnly: false),
                hoverAccent: .hex(0x0067C0))

        case .ubuntu1404:
            // Unity: dark aubergine caption (fixed), window buttons on the LEFT.
            return ThemeStyle(
                body: .solid(pal.background),
                textColor: pal.text,
                font: font(["Ubuntu", "Helvetica Neue"], 14),
                cornerRadius: 5,
                border: ThemeBorder(color: .hex(0x000000, alpha: 0.22), width: 1),
                caption: CaptionStyle(height: 26, fill: .solid(.hex(0x3C3B37)),
                                      buttonSide: .leading,
                                      controlColor: .hex(0xFFFFFF),
                                      hoverOnly: false),
                hoverAccent: .hex(0xDD4814))

        case .ubuntuModern:
            // GNOME / Yaru: light client-side-decoration header bar, window
            // controls on the RIGHT, rounded corners, Yaru orange accent.
            return ThemeStyle(
                body: .solid(pal.background),
                textColor: pal.text,
                font: font(["Ubuntu", "Helvetica Neue"], 14),
                cornerRadius: 12,
                border: ThemeBorder(color: .hex(0x000000, alpha: 0.18), width: 1),
                caption: CaptionStyle(height: 28, fill: .solid(.hex(0xF6F5F4)),
                                      buttonSide: .trailing,
                                      controlColor: .hex(0x3D3D3D),
                                      hoverOnly: false,
                                      separator: .hex(0x000000, alpha: 0.10)),
                hoverAccent: .hex(0xE95420))

        case .osxMavericks:
            // Classic Stickies, refined: subtle sheen on the top band + a hairline
            // separator, clean system font, near-square corners, soft paper shadow.
            return ThemeStyle(
                body: .solid(pal.background),
                textColor: pal.text,
                font: font(["Helvetica Neue", "Lucida Grande"], 14),
                cornerRadius: 2,
                border: ThemeBorder(color: .hex(0x000000, alpha: 0.14), width: 1),
                caption: CaptionStyle(height: 20,
                                      fill: .gradient(top: pal.background.lightened(0.06),
                                                      bottom: pal.caption),
                                      buttonSide: .trailing,
                                      controlColor: pal.text.withAlphaComponent(0.5),
                                      hoverOnly: true,
                                      separator: .hex(0x000000, alpha: 0.12)),
                hoverAccent: pal.text)

        case .macGlass:
            // Frosted glass: full-strength blur of the backdrop with only a faint
            // color wash (the blur is the point, not see-through transparency).
            return ThemeStyle(
                body: .vibrancy(material: .underWindowBackground,
                                tint: pal.background, tintAlpha: 0.10, effectAlpha: 1.0),
                textColor: .labelColor,
                font: font([".AppleSystemUIFont"], 14),
                cornerRadius: 14,
                border: ThemeBorder(color: .white.withAlphaComponent(0.22), width: 1),
                caption: CaptionStyle(height: 26,
                                      fill: .vibrancy(material: .underWindowBackground,
                                                      tint: .white, tintAlpha: 0.05, effectAlpha: 1.0),
                                      buttonSide: .trailing,
                                      controlColor: .labelColor,
                                      hoverOnly: true),
                hoverAccent: .controlAccentColor)
        }
    }
}

// MARK: - SwiftUI bridging

extension BackgroundFill {
    @ViewBuilder var view: some View {
        switch self {
        case .solid(let c):
            Color(nsColor: c)
        case .gradient(let top, let bottom):
            LinearGradient(colors: [Color(nsColor: top), Color(nsColor: bottom)],
                           startPoint: .top, endPoint: .bottom)
        case .vibrancy(let material, let tint, let tintAlpha, let effectAlpha):
            ZStack {
                VisualEffectBackground(material: material, alpha: effectAlpha)
                if let tint { Color(nsColor: tint).opacity(tintAlpha) }
            }
        }
    }
}

extension NSColor {
    /// Build a color from a 0xRRGGBB literal (optionally with alpha).
    static func hex(_ rgb: UInt32, alpha: CGFloat = 1.0) -> NSColor {
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: alpha)
    }

    /// Lighten toward white by `amount` (0…1). Used for the Mavericks top sheen.
    func lightened(_ amount: CGFloat) -> NSColor {
        guard let c = usingColorSpace(.sRGB) else { return self }
        return NSColor(srgbRed: min(c.redComponent + amount, 1),
                       green: min(c.greenComponent + amount, 1),
                       blue: min(c.blueComponent + amount, 1),
                       alpha: c.alphaComponent)
    }
}
