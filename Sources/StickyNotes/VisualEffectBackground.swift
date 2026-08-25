import SwiftUI
import AppKit

/// SwiftUI bridge to `NSVisualEffectView` for the frosted "Mac OS Glass" theme.
struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    /// Lower than 1 makes the frosting itself more transparent (text sits in a
    /// sibling layer, so it stays fully opaque).
    var alpha: CGFloat = 1.0

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        view.alphaValue = alpha
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.alphaValue = alpha
    }
}
