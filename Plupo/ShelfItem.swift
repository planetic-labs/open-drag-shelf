//
//  ShelfItem.swift
//  Plupo
//
//  Created by Antigravity on 06.06.2026.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

enum ShelfItemType: String, Codable {
    case file
    case text
    case url
    case image
}

struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let type: ShelfItemType
    
    // File properties
    var fileURL: URL?
    
    // Text properties
    var text: String?
    
    // URL properties
    var url: URL?
    var urlTitle: String?
    
    // Image properties
    var imageData: Data?
    var imageName: String?
    
    // Status
    var isLocked: Bool = false
    var dateAdded: Date = Date()
    
    // Computed properties for UI
    var title: String {
        switch type {
        case .file:
            return fileURL?.lastPathComponent ?? "Unknown File"
        case .text:
            if let text = text {
                let firstLine = text.components(separatedBy: .newlines).first ?? ""
                return firstLine.count > 30 ? String(firstLine.prefix(30)) + "..." : firstLine
            }
            return "Text Snippet"
        case .url:
            return urlTitle ?? url?.absoluteString ?? "URL Link"
        case .image:
            return imageName ?? "Image Snippet"
        }
    }
    
    var subtitle: String {
        switch type {
        case .file:
            if let size = fileSizeString {
                return size
            }
            return "Local File"
        case .text:
            return "\(text?.count ?? 0) characters"
        case .url:
            return url?.host ?? "Web Link"
        case .image:
            if let data = imageData, let img = NSImage(data: data) {
                return "\(Int(img.size.width)) × \(Int(img.size.height))"
            }
            return "Image"
        }
    }
    
    var fileSizeString: String? {
        guard let url = fileURL, url.isFileURL else { return nil }
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: Int64(fileSize))
            }
        } catch {
            // Log error or ignore
        }
        return nil
    }
    
    var icon: NSImage {
        switch type {
        case .file:
            if let url = fileURL {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            return NSWorkspace.shared.icon(for: .item)
        case .text:
            return NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Text") ?? NSImage()
        case .url:
            return NSImage(systemSymbolName: "link", accessibilityDescription: "Link") ?? NSImage()
        case .image:
            if let data = imageData, let image = NSImage(data: data) {
                return image
            }
            return NSImage(systemSymbolName: "photo", accessibilityDescription: "Image") ?? NSImage()
        }
    }
    
    // Helper to generate NSItemProvider for dragging OUT of Plupo
    func getItemProvider() -> NSItemProvider {
        let provider = NSItemProvider()
        
        switch type {
        case .file:
            if let url = fileURL {
                provider.registerFileRepresentation(for: url)
            }
        case .text:
            if let text = text {
                provider.registerObject(text as NSString, visibility: .all)
                // Also create a temp text file so it can be dragged into Finder
                if let tempURL = createTempFile(withContent: text, fileName: "Snippet.txt") {
                    provider.registerObject(tempURL as NSURL, visibility: .all)
                }
            }
        case .url:
            if let url = url {
                provider.registerObject(url as NSURL, visibility: .all)
                if let title = urlTitle {
                    provider.suggestedName = title
                }
            }
        case .image:
            if let data = imageData {
                let name = imageName ?? "DraggedImage.png"
                if let tempURL = createTempImageFile(data: data, fileName: name) {
                    provider.registerObject(tempURL as NSURL, visibility: .all)
                }
            }
        }
        
        return provider
    }
    
    private func createTempFile(withContent content: String, fileName: String) -> URL? {
        guard let data = content.data(using: .utf8) else { return nil }
        return createTempImageFile(data: data, fileName: fileName)
    }

    private func createTempImageFile(data: Data, fileName: String) -> URL? {
        let directory = PlupoTemporaryFiles.directory.appendingPathComponent(id.uuidString, isDirectory: true)
        // Provider names are untrusted: use only a single safe path component.
        let name = (fileName as NSString).lastPathComponent
        let safeName = name.isEmpty || name == "." || name == ".." ? "DraggedImage.png" : name
        let fileURL = directory.appendingPathComponent(safeName)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                    attributes: [.posixPermissions: 0o700])
            try data.write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
            return fileURL
        } catch {
            return nil
        }
    }

}

// Extension to help register file representation for drag-out
extension NSItemProvider {
    fileprivate func registerFileRepresentation(for url: URL) {
        // Register file URL
        self.registerObject(url as NSURL, visibility: .all)
        self.suggestedName = url.lastPathComponent
    }
}

// Keep drag exports isolated and remove them on normal exit and the next launch.
enum PlupoTemporaryFiles {
    static let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Plupo-DragExports", isDirectory: true)

    static func cleanup() {
        try? FileManager.default.removeItem(at: directory)
    }
}
