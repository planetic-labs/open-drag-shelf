import AppKit
import ImageIO

struct ShelfItem: Identifiable {
    enum Content {
        case file(URL)
        case text(String)
        case link(URL, title: String?)
        case image(Data, name: String)
    }

    let id: UUID
    let content: Content
    var isLocked = false
    let title: String
    let subtitle: String
    let thumbnail: NSImage

    init(id: UUID = UUID(), content: Content) {
        self.id = id
        self.content = content
        switch content {
        case .file(let url):
            title = url.lastPathComponent
            // Metadata is a snapshot at drop time; rendering never reads the file again.
            let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            subtitle = size.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) } ?? "Local File"
            thumbnail = NSWorkspace.shared.icon(forFile: url.path)
        case .text(let text):
            let firstLine = text.prefix(while: { !$0.isNewline })
            title = firstLine.count > 30 ? String(firstLine.prefix(30)) + "…" : String(firstLine)
            subtitle = "\(text.count) characters"
            thumbnail = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Text") ?? NSImage()
        case .link(let url, let name):
            title = name ?? url.absoluteString
            subtitle = url.host ?? "Link"
            thumbnail = NSImage(systemSymbolName: "link", accessibilityDescription: "Link") ?? NSImage()
        case .image(let data, let name):
            title = name
            let source = CGImageSourceCreateWithData(data as CFData, nil)
            let properties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
            if let width = properties?[kCGImagePropertyPixelWidth] as? Int,
               let height = properties?[kCGImagePropertyPixelHeight] as? Int {
                subtitle = "\(width) × \(height)"
            } else {
                subtitle = "Image"
            }
            let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                          kCGImageSourceThumbnailMaxPixelSize: 256,
                                          kCGImageSourceCreateThumbnailWithTransform: true]
            if let source, let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                thumbnail = NSImage(cgImage: image, size: .zero)
            } else {
                thumbnail = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image") ?? NSImage()
            }
        }
    }

    var exportURL: URL? {
        switch content {
        case .file(let url), .link(let url, _): return url
        case .text(let text):
            return PlupoTemporaryFiles.writeExport(Data(text.utf8), itemID: id, fileName: "Snippet.txt")
        case .image(let data, let name):
            return PlupoTemporaryFiles.writeExport(data, itemID: id, fileName: name)
        }
    }

    func pasteboardWriter() -> NSPasteboardWriting? {
        switch content {
        case .text(let text):
            let item = NSPasteboardItem()
            item.setString(text, forType: .string)
            if let url = exportURL { item.setString(url.absoluteString, forType: .fileURL) }
            return item
        default:
            return exportURL.map { $0 as NSURL }
        }
    }
}
