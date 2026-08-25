import SwiftUI

/// The themed top caption bar: "+" (new) and "×" (delete), positioned on the
/// side dictated by the theme (Ubuntu puts window controls on the left).
/// Paper themes (`hoverOnly`) reveal the buttons only on hover.
struct NoteCaptionView: View {
    let style: CaptionStyle
    let hovering: Bool
    let onNew: () -> Void
    let onDelete: () -> Void

    private var controlsVisible: Bool { hovering || !style.hoverOnly }

    var body: some View {
        let controlColor = Color(nsColor: style.controlColor)

        let newButton = Button(action: onNew) {
            Image(systemName: "plus").font(.system(size: 11, weight: .bold))
        }
        .buttonStyle(.plain)
        .help("New note")

        let closeButton = Button(action: onDelete) {
            Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
        }
        .buttonStyle(.plain)
        .help("Delete note")

        HStack(spacing: 8) {
            if style.buttonSide == .leading {
                // Unity-style: controls on the left (close, then new).
                closeButton
                newButton
                Spacer(minLength: 0)
            } else {
                newButton
                Spacer(minLength: 0)
                closeButton
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: style.height)
        .foregroundStyle(controlColor.opacity(controlsVisible ? 1.0 : 0.0))
        .background(style.fill.view)
        .overlay(alignment: .bottom) {
            if let separator = style.separator {
                Color(nsColor: separator).frame(height: 1)
            }
        }
    }
}
