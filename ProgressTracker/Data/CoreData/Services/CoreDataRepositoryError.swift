import Foundation

/// Defines errors thrown from Core Data repositories.
enum CoreDataRepositoryError: Error, LocalizedError {
    case entityNotFound
    case invalidManagedObject
    case saveFailure

    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "The requested object could not be found."
        case .invalidManagedObject:
            return "The managed object could not be created or updated."
        case .saveFailure:
            return "The data could not be saved."
        }
    }
}
