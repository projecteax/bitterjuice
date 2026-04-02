import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var battery: Double = 50
    @State private var head: Double = 50
    @State private var stress: Double = 50
    @State private var lowEnergy = false
    @State private var saveMessage = ""
    @State private var selectedNudge: String?
    @State private var streakDays = 0
    @State private var username: String = "friend"
    @State private var xpBalance: Int = 0
    @State private var level: Int = 1
    @State private var crews: [JuiceCrewItem] = []
    @State private var friendEvents: [FeedEventItem] = []
    @State private var isLoadingSocial = false
    private let repository = BitterJuiceRepository()
    private let healthKitService = HealthKitService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    xpCard
                    friendActivityCard
                    energyRingsCard
                    dailyCalibrationCard
                    badgesCard
                    nudgeCard
                    passiveTrackingCard
                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(saveMessage.contains("synced") || saveMessage.contains("Saved") ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.10), Color.purple.opacity(0.08), Color.blue.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .task {
                await loadProfileAndSocial()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hey \(username) 👋")
                .font(.title2.bold())
            Text("Small wins today become momentum tomorrow. Let's make this day count.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Label("🔥 \(streakDays) day streak", systemImage: "flame.fill")
                Label(lowEnergy ? "Low-energy mode" : "Normal mode", systemImage: lowEnergy ? "figure.mind.and.body" : "bolt.fill")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var xpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your progress")
                    .font(.headline)
                Spacer()
                Text("Level \(level)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: xpProgress)
                .tint(.pink)
                .scaleEffect(x: 1, y: 1.35, anchor: .center)

            HStack {
                Text("\(xpBalance) XP")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(xpToNextLevel) XP to next level")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var friendActivityCard: some View {
        let hasCrews = !crews.isEmpty
        let items = Array(friendEvents.prefix(3))
        return CrewLatestCard(
            isLoading: isLoadingSocial,
            hasCrews: hasCrews,
            events: items,
            messageForEvent: eventMessage,
            relativeDate: relativeDate,
            shortUserId: { String($0.prefix(6)) }
        )
    }

    private struct CrewLatestCard: View {
        let isLoading: Bool
        let hasCrews: Bool
        let events: [FeedEventItem]
        let messageForEvent: (FeedEventItem) -> String
        let relativeDate: (Date) -> String
        let shortUserId: (String) -> String

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Latest from your crew")
                        .font(.headline)
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    }
                }

                if !hasCrews {
                    Text("Join or create a crew to see friends’ activity here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if events.isEmpty {
                    Text("No new posts yet. Log something and it’ll show up here for others too.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(events) { event in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.pink.opacity(0.15))
                                    Text("✨")
                                        .font(.headline)
                                }
                                .frame(width: 34, height: 34)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(messageForEvent(event))
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(2)
                                    Text("by \(shortUserId(event.actorUserId)) · \(relativeDate(event.createdAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var energyRingsCard: some View {
        HStack(spacing: 12) {
            ringMetric(title: "Battery", value: battery, color: .green, icon: "battery.100")
            ringMetric(title: "Focus", value: head, color: .blue, icon: "brain.head.profile")
            ringMetric(title: "Stress", value: 100 - stress, color: .orange, icon: "wind")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var dailyCalibrationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily calibration")
                .font(.headline)

            metricSlider("🔋 Battery", value: $battery)
            metricSlider("🧠 Focus", value: $head)
            metricSlider("😮‍💨 Stress", value: $stress)

            Toggle("Today's pace: low energy", isOn: $lowEnergy)
                .toggleStyle(.switch)

            Button {
                Task {
                    guard let userId = sessionStore.userId else { return }
                    do {
                        try await repository.saveDailyCalibration(
                            userId: userId,
                            battery: battery,
                            head: head,
                            stress: stress,
                            lowEnergyMode: lowEnergy
                        )
                        saveMessage = "Saved. Your squad vibe is updated ✅"
                    } catch {
                        saveMessage = BitterJuiceRepository.userFacingSupabaseMessage(error)
                    }
                }
            } label: {
                Label("Save my state", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var nudgeCard: some View {
        let nudges = ["Focus sprint 🚀", "Hydrate 💧", "Quick walk 🌤️", "Mini reset 🧘"]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Pick a fun nudge")
                .font(.headline)
            Text("Local reminder only — not saved to Supabase.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(nudges, id: \.self) { nudge in
                        Button {
                            selectedNudge = nudge
                            saveMessage = "Nudge selected: \(nudge)"
                        } label: {
                            Text(nudge)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selectedNudge == nudge ? Color.pink.opacity(0.25) : Color.gray.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var passiveTrackingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Passive tracking")
                .font(.headline)
            Text("Sync sleep to celebrate recovery days, not just hustle.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                Task {
                    do {
                        try await healthKitService.requestAuthorization()
                        try await healthKitService.syncLastNightSleepAsPassiveEvent(squadId: nil)
                        saveMessage = "Sleep sync is not connected to Supabase yet — HealthKit permission saved for a future update."
                    } catch {
                        saveMessage = BitterJuiceRepository.userFacingSupabaseMessage(error)
                    }
                }
            } label: {
                Label("Sync last night sleep (preview)", systemImage: "bed.double.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var shortUserId: String {
        guard let id = sessionStore.userId else { return "friend" }
        return String(id.prefix(6))
    }

    @MainActor
    private func loadProfileAndSocial() async {
        guard let uid = sessionStore.userId else { return }
        if let stats = try? await repository.fetchProfileSnapshot(userId: uid) {
            streakDays = stats.streakDays
            username = stats.username
            xpBalance = stats.xpBalance
            level = stats.level
        }

        isLoadingSocial = true
        defer { isLoadingSocial = false }
        do {
            let list = try await repository.fetchMyJuiceCrews()
            crews = list
            guard let firstCrew = list.first else {
                friendEvents = []
                return
            }
            let events = try await repository.fetchFeedEvents(for: firstCrew.id)
            let mine = sessionStore.userId ?? ""
            friendEvents = events.filter { $0.actorUserId != mine }
        } catch {
            friendEvents = []
        }
    }

    private var xpToNextLevel: Int {
        max(0, xpForNextLevel(level) - xpBalance)
    }

    private var xpProgress: Double {
        let prev = xpForLevel(level)
        let next = xpForNextLevel(level)
        let denom = max(1, next - prev)
        return Double(max(0, min(xpBalance - prev, denom))) / Double(denom)
    }

    private func xpForLevel(_ level: Int) -> Int {
        max(0, (level - 1) * 250)
    }

    private func xpForNextLevel(_ level: Int) -> Int {
        xpForLevel(level + 1)
    }

    private var badgesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges & streaks")
                .font(.headline)

            let badges = earnedBadges
            if badges.isEmpty {
                Text("Log your first activity to unlock badges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                    ForEach(badges, id: \.title) { badge in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(badge.symbol)
                                .font(.title3)
                            Text(badge.title)
                                .font(.subheadline.weight(.semibold))
                            Text(badge.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private struct BadgeItem {
        let title: String
        let subtitle: String
        let symbol: String
    }

    private var earnedBadges: [BadgeItem] {
        var out: [BadgeItem] = []
        if streakDays >= 3 {
            out.append(.init(title: "Warm-up", subtitle: "3-day streak", symbol: "🔥"))
        }
        if streakDays >= 7 {
            out.append(.init(title: "Weekly rhythm", subtitle: "7-day streak", symbol: "🏅"))
        }
        if xpBalance >= 250 {
            out.append(.init(title: "Momentum", subtitle: "250 XP earned", symbol: "⚡️"))
        }
        if xpBalance >= 1000 {
            out.append(.init(title: "Stacking wins", subtitle: "1,000 XP earned", symbol: "🚀"))
        }
        return out
    }

    private func eventMessage(_ event: FeedEventItem) -> String {
        if let message = event.payload["message"] as? String, !message.isEmpty {
            return message
        }
        if let note = event.payload["note"] as? String, !note.isEmpty {
            return note
        }
        if let category = event.payload["category"] as? String,
           let minutes = event.payload["duration_minutes"] as? Int {
            return "\(category.capitalized) · \(minutes) min"
        }
        if let category = event.payload["category"] as? String,
           let minutes = event.payload["duration_minutes"] as? Double {
            return "\(category.capitalized) · \(Int(minutes)) min"
        }
        return "Shared an update with the crew."
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func metricSlider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...100, step: 1)
                .tint(.pink)
        }
    }

    private func ringMetric(title: String, value: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.20), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: value / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            .frame(width: 62, height: 62)
            Text(title)
                .font(.caption.weight(.semibold))
            Text("\(Int(value))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
