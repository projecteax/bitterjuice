import SwiftUI
import Supabase

struct ProfileView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var authService = AuthService()
    @State private var status = ""
    @State private var displayName = "Loading..."
    @State private var level = 1
    @State private var streakDays = 0
    @State private var xpBalance = 0

    private struct ProfileRow: Decodable {
        let username: String
        let level: Int
        let streak_days: Int
        let xp_balance: Int
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    socialCard
                    progressCard
                    challengesCard
                    accountCard
                    if !status.isEmpty {
                        Text(status)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("My Space")
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.08), Color.blue.opacity(0.08), Color.pink.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .task {
                await loadProfile()
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("😎")
                    .font(.largeTitle)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.title3.bold())
                Text("ID: \(shortUserId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Level \(level) · \(streakDays)-day streak", systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var socialCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Squad social")
                .font(.headline)
            HStack {
                socialMetric("XP", value: "\(xpBalance)")
                socialMetric("Level", value: "\(level)")
                socialMetric("Streak", value: "\(streakDays)")
            }
            Label("Challenges (coming soon — not in Supabase yet)", systemImage: "flag.checkered.2.crossed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress vibe")
                .font(.headline)
            Text("No computed analytics in the app yet — use Today and Log to build real data in Supabase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var challengesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active mini-challenges")
                .font(.headline)
            Text("None synced from the server. When we add a challenges table, entries will show here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.headline)
            Button(role: .destructive) {
                Task {
                    do {
                        try await authService.signOut()
                        status = "Signed out."
                    } catch {
                        status = BitterJuiceRepository.userFacingSupabaseMessage(error)
                    }
                }
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var shortUserId: String {
        guard let id = sessionStore.userId else { return "guest" }
        return String(id.prefix(6))
    }

    private func socialMetric(_ title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    private func loadProfile() async {
        guard let uid = sessionStore.userId else {
            displayName = "Guest"
            return
        }
        do {
            let rows: [ProfileRow] = try await SupabaseClientProvider.shared
                .from("profiles")
                .select("username,level,streak_days,xp_balance")
                .eq("id", value: uid)
                .limit(1)
                .execute()
                .value

            if let row = rows.first {
                displayName = row.username
                level = row.level
                streakDays = row.streak_days
                xpBalance = row.xp_balance
                return
            }

            if let session = try? await SupabaseClientProvider.shared.auth.session,
               let email = session.user.email {
                displayName = String(email.split(separator: "@").first ?? "User")
            } else {
                displayName = "User"
            }
        } catch {
            status = BitterJuiceRepository.userFacingSupabaseMessage(error)
            if displayName == "Loading..." {
                displayName = "User"
            }
        }
    }
}
