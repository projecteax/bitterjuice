import Foundation
import Supabase

@MainActor
final class SessionStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String?
    @Published var hasCompletedOnboarding: Bool = false

    private var authTask: Task<Void, Never>?

    private static func onboardingKey(for uid: String) -> String {
        "onboardingCompleted_\(uid)"
    }

    init() {
        let client = SupabaseClientProvider.shared
        authTask = Task { @MainActor in
            if let session = try? await client.auth.session, !session.isExpired {
                apply(session: session)
            }
            for await (_, session) in await client.auth.authStateChanges {
                if let session {
                    apply(session: session)
                } else {
                    clearAuthState()
                }
            }
        }
    }

    private func apply(session: Session) {
        guard !session.isExpired else {
            clearAuthState()
            return
        }
        let uid = session.user.id.uuidString
        isAuthenticated = true
        userId = uid
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey(for: uid))
    }

    private func clearAuthState() {
        isAuthenticated = false
        userId = nil
        hasCompletedOnboarding = false
    }

    func markOnboardingComplete() {
        guard let uid = userId else { return }
        UserDefaults.standard.set(true, forKey: Self.onboardingKey(for: uid))
        hasCompletedOnboarding = true
    }

    /// Call right after e-mail sign-in so RootView updates even if `authStateChanges` is slightly delayed.
    func finishReturningUserLogin(session: Session) {
        guard !session.isExpired else { return }
        let uid = session.user.id.uuidString
        isAuthenticated = true
        userId = uid
        UserDefaults.standard.set(true, forKey: Self.onboardingKey(for: uid))
        hasCompletedOnboarding = true
    }

    deinit {
        authTask?.cancel()
    }
}
