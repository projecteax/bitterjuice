import SwiftUI
import PhotosUI
import Supabase

struct ProfileView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var authService = AuthService()
    @State private var status = ""
    @State private var displayName = "Loading..."
    @State private var level = 1
    @State private var streakDays = 0
    @State private var xpBalance = 0
    @State private var avatarKey: String?
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isUploadingAvatar = false
    private let repository = BitterJuiceRepository()

    private struct ProfileRow: Decodable {
        let username: String
        let avatar_key: String?
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
                if let key = avatarKey, let url = repository.publicAvatarURL(for: key) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Text("😎").font(.largeTitle)
                        @unknown default:
                            Text("😎").font(.largeTitle)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Text("😎")
                        .font(.largeTitle)
                }
            }
            .frame(width: 72, height: 72)
            .overlay(
                Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )

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

            VStack(alignment: .trailing, spacing: 8) {
                PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                    Label(isUploadingAvatar ? "Uploading…" : "Edit", systemImage: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .disabled(isUploadingAvatar)
                .buttonStyle(.bordered)
                .onChange(of: avatarPickerItem) { _, newItem in
                    guard let newItem else { return }
                    Task { await uploadAvatar(item: newItem) }
                }
            }
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
                .select("username,avatar_key,level,streak_days,xp_balance")
                .eq("id", value: uid)
                .limit(1)
                .execute()
                .value

            if let row = rows.first {
                displayName = row.username
                avatarKey = row.avatar_key
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

    @MainActor
    private func uploadAvatar(item: PhotosPickerItem) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                status = "Could not read image."
                return
            }
            // Heuristic: PhotosPicker gives us an encoded file; default to jpg if unknown.
            let ext = "jpg"
            let key = try await repository.uploadMyAvatar(imageData: data, fileExtension: ext)
            avatarKey = key
            status = "Avatar updated ✅"
        } catch {
            status = BitterJuiceRepository.userFacingSupabaseMessage(error)
        }
    }
}
