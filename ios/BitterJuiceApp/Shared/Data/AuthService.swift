import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUserId: String?

    private let client = SupabaseClientProvider.shared

    init() {
        Task {
            if let session = try? await client.auth.session {
                currentUserId = session.user.id.uuidString
            }
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        if let session = try? await client.auth.session {
            currentUserId = session.user.id.uuidString
        }
    }

    func createAccountWithEmail(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
        if let session = try? await client.auth.session {
            currentUserId = session.user.id.uuidString
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUserId = nil
    }

    // TODO: Apple / Google — osobna konfiguracja w Supabase Dashboard
    func signInWithAppleCredential(idToken: String, nonce: String) async throws {
        throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In: skonfiguruj provider w Supabase."])
    }

    func signInWithGoogleIdToken(idToken: String, accessToken: String) async throws {
        throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In: skonfiguruj provider w Supabase."])
    }
}
