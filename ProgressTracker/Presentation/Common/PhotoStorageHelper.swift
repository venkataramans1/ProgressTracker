import Foundation

struct PhotoStorageHelper {
    private let storage: PhotoStoring
    private let fileManager: FileManager

    init(storage: PhotoStoring = DefaultPhotoStorage(), fileManager: FileManager = .default) {
        self.storage = storage
        self.fileManager = fileManager
    }

    func persist(imageData: Data, fileExtension: String = "jpg") throws -> URL {
        let temporaryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
        try imageData.write(to: temporaryURL)
        return try storage.persistIfNeeded(url: temporaryURL)
    }
}
