import SwiftUI

/// Root SwiftUI view for one note. Renders the chrome (background, caption bar,
/// corners, border) according to the note's theme, plus a right-click theme menu.
struct NoteView: View {
    @ObservedObject var model: NoteViewModel
    @State private var hovering = false

    var body: some View {
        let style = model.style

        VStack(spacing: 0) {
            ZStack {
                WindowDragView()
                NoteCaptionView(
                    style: style.caption,
                    hovering: hovering,
                    onNew: { model.onRequestNewNote?() },
                    onDelete: { model.onRequestDelete?() }
                )
            }
            .frame(height: style.caption.height)

            RichTextEditor(model: model, style: style)
        }
        .background(style.body.view)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(borderColor(style), lineWidth: style.border?.width ?? 0)
        )
        .onHover { hovering = $0 }
        .contextMenu { themeMenu }
    }

    private func borderColor(_ style: ThemeStyle) -> Color {
        guard let border = style.border else { return .clear }
        return Color(nsColor: border.color)
    }

    @ViewBuilder private var themeMenu: some View {
        Menu("Theme") {
            ForEach(NoteTheme.allCases) { theme in
                Button {
                    model.setTheme(theme)
                } label: {
                    if model.themeId == theme {
                        Label(theme.displayName, systemImage: "checkmark")
                    } else {
                        Text(theme.displayName)
                    }
                }
            }
        }
        Menu("Color") {
            ForEach(NoteColor.allCases) { color in
                Button {
                    model.setColor(color)
                } label: {
                    if model.colorId == color {
                        Label(color.displayName, systemImage: "checkmark")
                    } else {
                        Text(color.displayName)
                    }
                }
            }
        }
        Divider()
        Button("New Note") { model.onRequestNewNote?() }
        Button("Delete Note") { model.onRequestDelete?() }
    }
}
