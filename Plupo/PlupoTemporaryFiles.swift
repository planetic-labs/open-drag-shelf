import Foundation

// Exports must outlive the drag session: destinations may read them asynchronously.
enum PlupoTemporaryFiles {
    static let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Plupo-DragExports", isDirectory: true)

    static func writeExport(_ data: Data, itemID: UUID, fileName: String) -> URL? {
        let folder = directory.appendingPathComponent(itemID.uuidString, isDirectory: true)
        let name = (fileName as NSString).lastPathComponent
        let safeName = name.isEmpty || name == "." || name == ".." ? "Export" : name
        let url = folder.appendingPathComponent(safeName)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                                    attributes: [.posixPermissions: 0o700])
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            return url
        } catch { return nil }
    }

    static func cleanup() {
        try? FileManager.default.removeItem(at: directory)
    }
}
