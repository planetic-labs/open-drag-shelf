import AppKit
import UniformTypeIdentifiers

@main
struct RegressionTests {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            checks += 1
            guard condition() else { fatalError(message) }
        }
        func load(_ model: ShelfViewModel, _ providers: [NSItemProvider]) async -> Bool {
            await withCheckedContinuation { continuation in
                model.onDropFinished = { continuation.resume(returning: true) }
                if !model.handleDroppedProviders(providers) { continuation.resume(returning: false) }
            }
        }
        func text(_ item: ShelfItem) -> String? {
            if case .text(let value) = item.content { return value }
            return nil
        }

        var visibility = ShelfVisibilityState()
        expect(visibility.canAutoHide, "Empty idle shelf should auto-hide")
        visibility.apply(mode: .always)
        expect(visibility.desiredVisible && !visibility.canAutoHide, "Always mode must show immediately and reject old hide tasks")
        visibility.apply(mode: .shortcut)
        expect(!visibility.desiredVisible && !visibility.canAutoHide, "Manual mode must hide on entry and disable auto-hide")
        visibility.itemCount = 1
        visibility.apply(mode: .dragStarts)
        expect(visibility.desiredVisible && !visibility.canAutoHide, "Returning to drag mode must show existing items")
        visibility.itemCount = 0
        visibility.dragSources = ["monitor", "shelf"]
        expect(!visibility.canAutoHide, "An active drag blocks auto-hide")
        visibility.dragSources.remove("monitor")
        expect(!visibility.canAutoHide, "One drag monitor ending must not end the native session")
        visibility.dragSources.removeAll()
        visibility.isLoadingDrop = true
        expect(!visibility.canAutoHide, "Slow provider loading blocks auto-hide")
        visibility.isLoadingDrop = false
        expect(visibility.canAutoHide, "Hide becomes eligible when the last load finishes")

        visibility.hasDropError = true
        expect(!visibility.canAutoHide, "A drop error must remain visible until dismissed")
        visibility.hasDropError = false

        let model = ShelfViewModel()
        let unsupported = NSItemProvider()
        unsupported.registerDataRepresentation(forTypeIdentifier: "com.plupo.opaque", visibility: .all) { done in
            done(Data([1]), nil); return nil
        }
        expect(!model.handleDroppedProviders([unsupported]), "Unknown-only drops must be rejected")
        let multi = NSItemProvider()
        multi.registerDataRepresentation(forTypeIdentifier: "com.plupo.opaque", visibility: .all) { done in
            done(Data([1]), nil); return nil
        }
        multi.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { done in
            done(Data("hello".utf8), nil); return nil
        }
        let acceptedMulti = await load(model, [multi])
        expect(acceptedMulti && model.items.count == 1 && text(model.items[0]) == "hello", "Supported text after an opaque type must load")
        let fallback = NSItemProvider()
        fallback.registerDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier, visibility: .all) { done in
            done(nil, NSError(domain: "RegressionTest", code: 1)); return nil
        }
        fallback.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { done in
            done(Data("fallback".utf8), nil); return nil
        }
        let acceptedFallback = await load(model, [fallback])
        expect(acceptedFallback && text(model.items.last!) == "fallback", "A failed preferred representation must try the next supported type")

        let item = model.items[0]
        model.finishDrag(itemID: item.id, operation: [], keepItems: false)
        expect(model.items.count == 2, "Rejected/cancelled drags must keep shelf content")
        model.toggleLock(for: item)
        model.finishDrag(itemID: item.id, operation: .copy, keepItems: false)
        expect(model.items.count == 2, "Locked items must survive a successful drag")
        model.toggleLock(for: item)
        expect(!model.items[0].isLocked, "The same toggle must unlock an item")
        model.finishDrag(itemID: item.id, operation: .copy, keepItems: true)
        expect(model.items.count == 2, "Keep-items preference must preserve accepted drags")
        model.finishDrag(itemID: item.id, operation: .copy, keepItems: false)
        expect(model.items.count == 1, "An accepted drag removes an unlocked item when requested")
        // Use current lock state, not the copy captured at drag start.
        let second = model.items[0]
        model.toggleLock(for: second)
        model.clearAll()
        expect(model.items.count == 1, "Clear all must retain locked items")

        let failed = NSItemProvider()
        failed.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { done in
            done(nil, NSError(domain: "RegressionTest", code: 2)); return nil
        }
        _ = await load(model, [failed])
        expect(model.dropError != nil && !model.isLoadingDrop, "Failed supported drops must finish and present feedback")

        if case .text(let value) = ShelfViewModel.decode("custom:plain text" as NSString, type: UTType.plainText.identifier, name: nil) {
            expect(value == "custom:plain text", "Plain text with a colon must remain text")
        } else { fatalError("Text was misclassified as a URL") }
        expect(ShelfViewModel.decode("https://example.com" as NSString, type: UTType.fileURL.identifier, name: nil) == nil,
               "Web links must not be accepted as local files")
        model.dismissDropError()
        expect(model.dropError == nil, "The user must be able to dismiss drop feedback")
        let richOnly = NSItemProvider()
        richOnly.registerDataRepresentation(forTypeIdentifier: UTType.rtf.identifier, visibility: .all) { done in
            done(Data("{\\rtf1 raw}".utf8), nil); return nil
        }
        expect(!model.handleDroppedProviders([richOnly]), "Rich-text bytes must not be shown as plain text")
        let safeID = UUID()
        let export = PlupoTemporaryFiles.writeExport(Data("private".utf8), itemID: safeID, fileName: "../../outside.txt")!
        defer { try? FileManager.default.removeItem(at: export.deletingLastPathComponent()) }
        expect(export.deletingLastPathComponent().lastPathComponent == safeID.uuidString, "Export filenames must not escape their directory")
        let permissions = try FileManager.default.attributesOfItem(atPath: export.path)[.posixPermissions] as! NSNumber
        expect(permissions.intValue == 0o600, "Temporary exports must be private")
        let writer = ShelfItem(content: .text("original text")).pasteboardWriter() as? NSPasteboardItem
        expect(writer?.string(forType: .string) == "original text" && writer?.string(forType: .fileURL) != nil,
               "Text must export both plain text and a Finder-compatible file")
        if let path = writer?.string(forType: .fileURL).flatMap(URL.init(string:)) {
            try? FileManager.default.removeItem(at: path.deletingLastPathComponent())
        }
        print("Passed \(checks) regression checks")
    }
}
