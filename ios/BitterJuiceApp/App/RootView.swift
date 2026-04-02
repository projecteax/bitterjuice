import SwiftUI

struct RootView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.isAuthenticated, sessionStore.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingEntryView()
            }
        }
    }
}
