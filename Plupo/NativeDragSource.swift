import SwiftUI
import AppKit

// A real AppKit drag source reports whether the destination accepted the drop.
struct NativeDragSource: NSViewRepresentable {
    let item: ShelfItem
    let viewModel: ShelfViewModel
    let preview: () -> Void

    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ view: DragView, context: Context) {
        view.item = item
        view.viewModel = viewModel
        view.preview = preview
    }

    class DragView: NSView, NSDraggingSource {
        var item: ShelfItem?
        weak var viewModel: ShelfViewModel?
        var preview: (() -> Void)?
        private var mouseDownPoint: NSPoint?
        private var draggedID: UUID?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            mouseDownPoint = convert(event.locationInWindow, from: nil)
            if event.clickCount == 2 { preview?() }
        }

        override func mouseUp(with event: NSEvent) { mouseDownPoint = nil }

        override func mouseDragged(with event: NSEvent) {
            guard let start = mouseDownPoint, let item else { return }
            let point = convert(event.locationInWindow, from: nil)
            guard hypot(point.x - start.x, point.y - start.y) >= 4 else { return }
            guard let writer = item.pasteboardWriter() else { return }
            mouseDownPoint = nil
            draggedID = item.id
            WindowManager.shared.dragDidBegin(source: "shelf")
            let draggingItem = NSDraggingItem(pasteboardWriter: writer)
            draggingItem.setDraggingFrame(NSRect(x: point.x - 16, y: point.y - 16, width: 32, height: 32), contents: item.thumbnail)
            beginDraggingSession(with: [draggingItem], event: event, source: self)
        }

        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            // Reordering/duplicating items inside this shelf is not a supported operation.
            context == .outsideApplication ? .copy : []
        }

        func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
            if let draggedID {
                viewModel?.finishDrag(itemID: draggedID, operation: operation,
                                      keepItems: PreferencesStore.shared.keepItemsAfterDrag)
            }
            draggedID = nil
            WindowManager.shared.dragDidEnd(source: "shelf")
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            guard let item else { return nil }
            let menu = NSMenu()
            for (title, action) in [(item.isLocked ? "Unlock Item" : "Lock Item", #selector(toggleLock)),
                                    ("Quick Look", #selector(showPreview)), ("Remove", #selector(remove))] {
                let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
                entry.target = self
                menu.addItem(entry)
            }
            return menu
        }

        @objc private func toggleLock() { if let item { viewModel?.toggleLock(for: item) } }
        @objc private func showPreview() { preview?() }
        @objc private func remove() { if let item { viewModel?.removeItem(item) } }
    }
}
