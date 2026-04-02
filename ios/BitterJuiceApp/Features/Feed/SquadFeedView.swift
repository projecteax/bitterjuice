import SwiftUI
import UIKit

struct SquadFeedView: View {
    @State private var crews: [JuiceCrewItem] = []
    @State private var selectedCrew: JuiceCrewItem?
    @State private var events: [FeedEventItem] = []
    @State private var status = ""
    @State private var reactionTargetEventId: String?
    @State private var showReactionSheet = false
    @State private var showCrewSheet = false
    @State private var newCrewName = ""
    @State private var joinCrewId = ""
    @State private var isLoadingFeed = false
    @State private var profileCache: [String: PublicProfileItem] = [:]
    @State private var isRefreshingCrews = false
    @State private var crewSheetError = ""
    @State private var crewSheetBusy = false
    @State private var showChallengeSheet = false
    @State private var challengePickId = "running"
    @State private var challengeGoalMetric: ChallengeMetric = .distance
    @State private var challengeTargetText = "400"
    @State private var challengeStart = Date()
    @State private var challengeEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date().addingTimeInterval(7 * 86400)
    @State private var challengePrize = ""
    @State private var challengeNote = ""
    @State private var challengeBusy = false
    @State private var crewMembers: [PublicProfileItem] = []
    @State private var selectedInviteeId: String?

    private let repository = BitterJuiceRepository()
    private let activityTitles: [String: String] = [
        // Sport
        "running": "Running",
        "cycling": "Cycling",
        "rollerskiing": "Rollerskiing",
        "swimming": "Swimming",
        "tennis": "Tennis",
        "volleyball": "Volleyball",
        "gym": "Gym",
        "yoga": "Yoga",
        "sport_other": "Sport (other)",

        // Creative
        "painting": "Painting",
        "drawing": "Drawing",
        "playing_music": "Playing music",
        "writing": "Writing",
        "renovations": "Renovations",
        "decoupage": "Decoupage",
        "creative_other": "Creative (other)",

        // Work
        "worked_less_than_8h": "Worked < 8h",
        "low_priority_tasks": "Low priority tasks",
        "work_other": "Work (other)",

        // Recovery
        "journaling": "Journaling",
        "walk": "Walk",
        "reading_book": "Reading book",
        "meditation": "Meditation",

        // Misc
        "general": "Something else"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                crewHeaderCard

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if selectedCrew == nil {
                            emptyNoCrewView
                        } else if !isLoadingFeed && events.isEmpty {
                            emptyFeedHint
                        }

                        ForEach(events) { event in
                            feedCard(event: event)
                        }
                    }
                    .padding(.horizontal)
                }

                if !status.isEmpty {
                    Text(status)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Juice Crew")
            // One trailing group avoids UIKit NavigationButtonBar width==0 constraint fights
            // (two separate ToolbarItem(placement: .topBarTrailing) often log Auto Layout warnings).
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showCrewSheet = true
                    } label: {
                        Image(systemName: "person.3.fill")
                    }
                    .accessibilityLabel("Crews")

                    Button {
                        showChallengeSheet = true
                    } label: {
                        Image(systemName: "flag.checkered")
                    }
                    .accessibilityLabel("Challenge")

                    Button {
                        Task { await refreshCrews(); await loadFeed() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                    .disabled(isRefreshingCrews || isLoadingFeed)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .task {
                // Let the tab finish layout before networking; overlapping first keyboard focus + Supabase
                // on a Debug build can stall the main thread for many seconds on device.
                await Task.yield()
                try? await Task.sleep(for: .milliseconds(500))
                await refreshCrews()
            }
            .onChange(of: selectedCrew?.id) { _, _ in
                Task { await loadFeed() }
            }
            .onChange(of: showCrewSheet) { _, isOpen in
                if isOpen { crewSheetError = "" }
            }
            // fullScreenCover avoids sheet+keyboard competing for vertical layout (common source of multi‑second stalls).
            .fullScreenCover(isPresented: $showCrewSheet) {
                juiceCrewSheet
            }
            .sheet(isPresented: $showChallengeSheet) {
                challengeSheet
            }
            .onChange(of: showChallengeSheet) { _, isOpen in
                if isOpen {
                    Task { await loadCrewMembersForChallenge() }
                }
            }
        }
    }

    private enum ChallengeMetric: String, CaseIterable, Identifiable {
        case sessions = "Sessions"
        case minutes = "Minutes"
        case distance = "Distance (km)"
        var id: String { rawValue }
        var apiValue: String {
            switch self {
            case .sessions: return "sessions"
            case .minutes: return "minutes"
            case .distance: return "distance"
            }
        }
        var unit: String {
            switch self {
            case .sessions: return "sessions"
            case .minutes: return "min"
            case .distance: return "km"
            }
        }
        var placeholder: String {
            switch self {
            case .sessions: return "10"
            case .minutes: return "10"
            case .distance: return "400"
            }
        }
    }

    private var crewHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your motivation circle")
                .font(.title3.bold())
            Text("Create a crew, share its invite ID with friends, or paste one they sent you. The feed is only real posts from Supabase — no demo cards.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let crew = selectedCrew {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(crew.name)
                            .font(.headline)
                        Text(crew.id)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button("Copy invite") {
                        UIPasteboard.general.string = crew.id
                        status = "Crew ID copied — send it to friends so they can join."
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .controlSize(.small)
                }
            } else {
                Text("You’re not in a crew yet — open Crews to create or join.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showCrewSheet = true
            } label: {
                Label(selectedCrew == nil ? "Create or join a crew" : "Switch crew", systemImage: "person.badge.plus")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }

    private var emptyNoCrewView: some View {
        VStack(spacing: 12) {
            Text("No crew selected")
                .font(.headline)
            Text("Tap “Crews” above to start your own Juice Crew or join with a friend’s ID.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyFeedHint: some View {
        VStack(spacing: 8) {
            Text("Quiet in here")
                .font(.headline)
            Text("Log an activity on the Log tab with this crew ID and “Share to squad feed” on — then pull to refresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// ScrollView + rounded fields (no Form). Shown in `fullScreenCover` so keyboard isn’t fighting a sheet detent.
    private var juiceCrewSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Juice Crews")
                        .font(.title2.bold())
                    Spacer()
                    Button("Done") {
                        showCrewSheet = false
                    }
                    .font(.body.weight(.semibold))
                }

                crewSheetSection(title: "Your crews") {
                    if crews.isEmpty {
                        Text("None yet — create one below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(crews.enumerated()), id: \.element.id) { index, crew in
                                Button {
                                    selectedCrew = crew
                                    showCrewSheet = false
                                } label: {
                                    HStack {
                                        Text(crew.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if crew.id == selectedCrew?.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.pink)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                if index < crews.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                crewSheetSection(title: "Start a crew") {
                    TextField("Name (e.g. Morning Grinders)", text: $newCrewName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                    if crewSheetBusy {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Creating…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Create") {
                        Task { await createCrew() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .disabled(
                        crewSheetBusy
                            || newCrewName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    if !crewSheetError.isEmpty {
                        Text(crewSheetError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                crewSheetSection(title: "Join a friend’s crew") {
                    TextField("Paste crew UUID", text: $joinCrewId)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Join crew") {
                        Task { await joinCrew() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(crewSheetBusy || joinCrewId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("Friends share this ID with you — there’s no public directory in the MVP.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func crewSheetSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func refreshCrews() async {
        isRefreshingCrews = true
        defer { isRefreshingCrews = false }
        do {
            let list = try await repository.fetchMyJuiceCrews()
            await MainActor.run {
                crews = list
                if let sel = selectedCrew, list.contains(where: { $0.id == sel.id }) {
                    selectedCrew = list.first { $0.id == sel.id }
                } else if selectedCrew == nil, let first = list.first {
                    selectedCrew = first
                } else if let sel = selectedCrew, !list.contains(where: { $0.id == sel.id }) {
                    selectedCrew = list.first
                }
                if list.isEmpty {
                    selectedCrew = nil
                    events = []
                    status = ""
                }
            }
        } catch {
            await MainActor.run {
                status = BitterJuiceRepository.userFacingSupabaseMessage(error)
            }
        }
    }

    private func createCrew() async {
        await MainActor.run {
            crewSheetError = ""
            status = ""
            crewSheetBusy = true
        }
        do {
            let id = try await repository.createJuiceCrew(name: newCrewName)
            await MainActor.run { newCrewName = "" }
            await refreshCrews()
            await MainActor.run {
                crewSheetBusy = false
                if let match = crews.first(where: { $0.id == id.uuidString }) {
                    selectedCrew = match
                }
                showCrewSheet = false
                status = "Crew created — share the ID from the header."
            }
        } catch {
            await MainActor.run {
                crewSheetBusy = false
                let message = BitterJuiceRepository.userFacingSupabaseMessage(error)
                crewSheetError = message
                status = message
            }
        }
    }

    private func joinCrew() async {
        let trimmed = joinCrewId.trimmingCharacters(in: .whitespacesAndNewlines)
        await MainActor.run {
            crewSheetError = ""
            status = ""
            crewSheetBusy = true
        }
        do {
            try await repository.joinJuiceCrew(squadId: trimmed)
            await MainActor.run { joinCrewId = "" }
            await refreshCrews()
            await MainActor.run {
                crewSheetBusy = false
                if let normalized = UUID(uuidString: trimmed)?.uuidString,
                   let joined = crews.first(where: { $0.id.caseInsensitiveCompare(normalized) == .orderedSame }) {
                    selectedCrew = joined
                }
                showCrewSheet = false
                status = "You’re in — feed will load for this crew."
            }
        } catch {
            await MainActor.run {
                crewSheetBusy = false
                let message = BitterJuiceRepository.userFacingSupabaseMessage(error)
                crewSheetError = message
                status = message
            }
        }
    }

    private func loadFeed() async {
        guard let crewId = selectedCrew?.id, UUID(uuidString: crewId) != nil else {
            await MainActor.run {
                events = []
                status = ""
            }
            return
        }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            let loaded = try await repository.fetchFeedEvents(for: crewId)
            await MainActor.run {
                events = loaded
                if loaded.isEmpty {
                    status = ""
                } else {
                    status = "\(loaded.count) post(s)."
                }
            }
            await refreshProfiles(for: loaded)
        } catch {
            await MainActor.run {
                events = []
                status = BitterJuiceRepository.userFacingSupabaseMessage(error)
            }
        }
    }

    private var challengeSheet: some View {
        NavigationStack {
            Form {
                Section("Invite") {
                    if crewMembers.isEmpty {
                        Text("No members loaded. Make sure you selected a crew.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Crew member", selection: $selectedInviteeId) {
                            Text("Select…").tag(String?.none)
                            ForEach(crewMembers) { p in
                                Text(p.username).tag(String?(p.id))
                            }
                        }
                    }
                    if let crew = selectedCrew {
                        Text("Crew: \(crew.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Goal") {
                    Picker("Activity", selection: $challengePickId) {
                        ForEach(activityTitles.keys.sorted(), id: \.self) { key in
                            Text(activityTitles[key] ?? key).tag(key)
                        }
                    }

                    Picker("Metric", selection: $challengeGoalMetric) {
                        ForEach(ChallengeMetric.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }

                    HStack {
                        TextField("Target", text: $challengeTargetText)
                            .keyboardType(.decimalPad)
                        Text(challengeGoalMetric.unit)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("When") {
                    DatePicker("Starts", selection: $challengeStart)
                    DatePicker("Ends", selection: $challengeEnd)
                }

                Section("Prize & note") {
                    TextField("Prize proposal (optional)", text: $challengePrize)
                    TextField("Note (optional)", text: $challengeNote, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("New challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showChallengeSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(challengeBusy ? "Sending…" : "Send") {
                        Task { await createChallenge() }
                    }
                    .disabled(challengeBusy || selectedInviteeId == nil)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func createChallenge() async {
        challengeBusy = true
        defer { challengeBusy = false }
        do {
            let target = Double(challengeTargetText.replacingOccurrences(of: ",", with: ".")) ?? 0
            try await repository.createChallenge(
                inviteeId: selectedInviteeId ?? "",
                crewId: selectedCrew?.id,
                activityPickId: challengePickId,
                goalMetric: challengeGoalMetric.apiValue,
                targetValue: target,
                targetUnit: challengeGoalMetric.unit,
                startAt: challengeStart,
                endAt: challengeEnd,
                prizeProposal: challengePrize,
                note: challengeNote
            )
            await MainActor.run {
                status = "Challenge sent ✅"
                showChallengeSheet = false
                challengePrize = ""
                challengeNote = ""
                challengeGoalMetric = .distance
                challengeTargetText = challengeGoalMetric.placeholder
                selectedInviteeId = nil
            }
        } catch {
            await MainActor.run { status = BitterJuiceRepository.userFacingSupabaseMessage(error) }
        }
    }

    private func loadCrewMembersForChallenge() async {
        guard let crewId = selectedCrew?.id else {
            await MainActor.run { crewMembers = []; selectedInviteeId = nil }
            return
        }
        do {
            let members = try await repository.fetchCrewMemberProfiles(crewId: crewId)
            let myId = (try? await SupabaseClientProvider.shared.auth.session.user.id.uuidString) ?? ""
            await MainActor.run {
                // Don’t allow selecting yourself
                crewMembers = members.filter { $0.id != myId }.sorted { $0.username < $1.username }
                if selectedInviteeId == nil, let first = crewMembers.first?.id {
                    selectedInviteeId = first
                }
            }
        } catch {
            await MainActor.run { crewMembers = []; selectedInviteeId = nil }
        }
    }

    private func refreshProfiles(for events: [FeedEventItem]) async {
        let ids = Array(Set(events.map(\.actorUserId))).filter { profileCache[$0] == nil }
        guard !ids.isEmpty else { return }
        do {
            let rows = try await repository.fetchPublicProfiles(userIds: ids)
            await MainActor.run {
                for p in rows { profileCache[p.id] = p }
            }
        } catch {
            // Keep cache empty; UI falls back to short id.
        }
    }

    private func feedCard(event: FeedEventItem) -> some View {
        let profile = profileCache[event.actorUserId]
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 10) {
                    avatarView(avatarKey: profile?.avatarKey, fallbackName: profile?.username ?? shortUserId(event.actorUserId))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile?.username ?? shortUserId(event.actorUserId))
                            .font(.subheadline.weight(.semibold))
                        Text(relativeDate(event.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Text(eventTitle(event))
                .font(.headline)
            Text(eventSubtitle(event))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                reactionPill("🫶 Proud") { react(eventId: event.id, type: "proud") }
                reactionPill("🔥 Push") { react(eventId: event.id, type: "keepItUp") }
                reactionPill("🛋️ Rest") { react(eventId: event.id, type: "restABit") }
            }

            Label("Long-press the card for the same reactions", systemImage: "hand.tap.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onLongPressGesture {
            reactionTargetEventId = event.id
            showReactionSheet = true
        }
        .contextMenu {
            Button("I'm proud of you 🫶") { react(eventId: event.id, type: "proud") }
            Button("Keep pushing 🔥") { react(eventId: event.id, type: "keepItUp") }
            Button("Take a break 🛋️") { react(eventId: event.id, type: "restABit") }
        }
        .confirmationDialog("React to this activity", isPresented: $showReactionSheet, titleVisibility: .visible) {
            if reactionTargetEventId == event.id {
                Button("I'm proud of you 🫶") { react(eventId: event.id, type: "proud") }
                Button("Keep pushing 🔥") { react(eventId: event.id, type: "keepItUp") }
                Button("Take a break 🛋️") { react(eventId: event.id, type: "restABit") }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func reactionPill(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.pink.opacity(0.18))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

    private func eventTitle(_ event: FeedEventItem) -> String {
        // Use the pick id first (industry standard: content-first), fallback to eventType.
        if let pickId = event.payload["interest_tag_id"] as? String,
           let title = activityTitles[pickId] {
            return title
        }
        if let category = event.payload["category"] as? String, !category.isEmpty {
            return category.capitalized
        }
        return event.eventType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func eventSubtitle(_ event: FeedEventItem) -> String {
        if let minutes = event.payload["duration_minutes"] as? Int {
            return "\(minutes) min"
        }
        if let minutes = event.payload["duration_minutes"] as? Double {
            return "\(Int(minutes)) min"
        }
        if let note = event.payload["note"] as? String, !note.isEmpty {
            return note
        }
        return eventMessage(event)
    }

    private func shortUserId(_ id: String) -> String {
        String(id.prefix(6))
    }

    private func avatarView(avatarKey: String?, fallbackName: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.pink.opacity(0.18))

            if let avatarKey,
               let url = repository.publicAvatarURL(for: avatarKey) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().scaleEffect(0.7)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Text(String(fallbackName.prefix(1)).uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.pink)
                    @unknown default:
                        Text(String(fallbackName.prefix(1)).uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.pink)
                    }
                }
                .clipShape(Circle())
            } else {
                Text(String(fallbackName.prefix(1)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.pink)
            }
        }
        .frame(width: 34, height: 34)
        .overlay(Circle().strokeBorder(Color.pink.opacity(0.25), lineWidth: 1))
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func react(eventId: String, type: String) {
        Task {
            do {
                try await repository.sendReaction(feedEventId: eventId, reaction: type)
                await MainActor.run { status = "Reaction saved 💬" }
            } catch {
                await MainActor.run { status = BitterJuiceRepository.userFacingSupabaseMessage(error) }
            }
        }
    }
}
