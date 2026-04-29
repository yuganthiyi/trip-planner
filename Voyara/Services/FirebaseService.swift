import Foundation

actor FirebaseService {
    static let shared = FirebaseService()

    private init() {}

    func uploadFile(data: Data, path: String) async throws -> URL {
        // Placeholder: return a dummy URL
        return URL(string: "https://example.com/")!
    }

    func saveDocument(collection: String, data: [String: Any]) async throws -> String {
        return UUID().uuidString
    }

    func fetchDocuments(collection: String) async throws -> [[String: Any]] {
        return []
    }
}
