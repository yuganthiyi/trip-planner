import Foundation

actor AuthService {
    static let shared = AuthService()

    private init() {}

    func signIn(email: String, password: String) async throws -> String {
        // Placeholder: return user id
        return UUID().uuidString
    }

    func signUp(email: String, password: String, displayName: String) async throws -> String {
        return UUID().uuidString
    }

    func signOut() async throws {
        // No-op
    }
}
