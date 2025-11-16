import Foundation

protocol PhotoStoring {
    func persistIfNeeded(url: URL) throws -> URL
    func remove(url: URL) throws
}

struct DefaultPhotoStorage: PhotoStoring {
    private let fileManager: FileManager
    private let documentsURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentsURL = dir
        } else {
            documentsURL = fileManager.temporaryDirectory
        }
    }

    func persistIfNeeded(url: URL) throws -> URL {
        guard url.isFileURL else { return url }
        if url.path.hasPrefix(documentsURL.path) {
            return url
        }
        let destination = documentsURL.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: destination.path) {
            return destination
        }
        try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.copyItem(at: url, to: destination)
        return destination
    }

    func remove(url: URL) throws {
        guard url.isFileURL, fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
}
