import AppKit
import Quartz

final class PreviewController: NSObject, NSWindowDelegate {
    static let shared = PreviewController()
    private var window: NSWindow?
    private var preview: QLPreviewView?
    private var linkURL: URL?

    func show(_ item: ShelfItem) {
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                                  styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.delegate = self
            self.window = window
        }
        guard let window else { return }
        preview?.close()
        preview = nil
        linkURL = nil
        window.title = item.title
        switch item.content {
        case .link(let url, _):
            let label = NSTextField(wrappingLabelWithString: url.absoluteString)
            label.isSelectable = true
            let button = NSButton(title: "Open Link", target: self, action: #selector(openLink))
            linkURL = url
            let stack = NSStackView(views: [label, button])
            stack.orientation = .vertical
            stack.spacing = 20
            let container = NSView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
                stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            window.contentView = container
        default:
            guard let url = item.exportURL,
                  let view = QLPreviewView(frame: NSRect(x: 0, y: 0, width: 640, height: 480), style: .normal) else {
                let alert = NSAlert()
                alert.messageText = "Could not preview this item"
                alert.informativeText = "The file may no longer be available."
                alert.runModal()
                return
            }
            view.previewItem = url as NSURL
            view.autostarts = false
            view.shouldCloseWithWindow = false
            window.contentView = view
            preview = view
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openLink(_ sender: NSButton) {
        if let url = linkURL { NSWorkspace.shared.open(url) }
    }

    func windowWillClose(_ notification: Notification) {
        preview?.close()
        preview = nil
        window?.contentView = nil
    }
}
