import SwiftUI

@main
struct VidStillsApp: App {

    var body: some Scene {
        Window("VidStills", id: "main") {
            ContentView()
                .background(WindowAccessor { window in
                    configure(window: window)
                })
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    // Lock the window size and make sure the chamois canvas bleeds under the
    // traffic-light area where the title bar used to live.
    private func configure(window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.setContentSize(NSSize(width: WindowSize.width, height: WindowSize.height))
        window.minSize = NSSize(width: WindowSize.width, height: WindowSize.height)
        window.maxSize = NSSize(width: WindowSize.width, height: WindowSize.height)
        window.backgroundColor = NSColor(
            srgbRed: 0.941, green: 0.898, blue: 0.800, alpha: 1.0
        )
        // Open with nothing focused. AppKit auto-assigns first responder to the
        // first focusable view, which paints a ring on Browse before the user
        // has done anything. Clear it here and on the next runloop tick to
        // beat SwiftUI's own focus pass.
        window.initialFirstResponder = nil
        window.makeFirstResponder(nil)
        DispatchQueue.main.async { window.makeFirstResponder(nil) }
    }
}

// Bridge to grab the underlying NSWindow once SwiftUI has materialised it.
// Calls `onResolved` exactly once per window lifetime so re-renders can't
// repeatedly trample first-responder state.
private struct WindowAccessor: NSViewRepresentable {
    let onResolved: (NSWindow) -> Void

    final class Coordinator { var configured = false }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let coordinator = context.coordinator
        DispatchQueue.main.async { [weak view] in
            guard let view, let window = view.window, !coordinator.configured else { return }
            coordinator.configured = true
            onResolved(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard !context.coordinator.configured else { return }
        let coordinator = context.coordinator
        DispatchQueue.main.async { [weak nsView] in
            guard let nsView, let window = nsView.window, !coordinator.configured else { return }
            coordinator.configured = true
            onResolved(window)
        }
    }
}
