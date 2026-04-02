import SwiftUI

struct ActivityLogView: View {
    @State private var mode: Mode = .log
    @State private var selectedActivityId = "general"
    @State private var durationPreset: DurationPreset = .min30to60
    @State private var note = ""
    @State private var proofAssetKey: String?
    @State private var status = ""
    @State private var selectedMood = "🔥"
    @State private var crews: [JuiceCrewItem] = []
    @State private var selectedCrewIds: Set<String> = []
    @State private var isLoadingCrews = false
    @State private var isLoadingRecents = false
    @State private var recentActivityIds: [String] = []
    @State private var topActivityIds: [String] = []
    @State private var activityMode: ActivityMode = .myPicks
    @State private var isActivityPickerOpen = false
    @State private var isNoteOpen = false
    @State private var history: [BitterJuiceRepository.ActivityLogItem] = []
    @State private var isLoadingHistory = false
    @State private var historyStatus = ""
    @State private var editingLog: BitterJuiceRepository.ActivityLogItem?
    @State private var challenges: [BitterJuiceRepository.ChallengeItem] = []
    @State private var challengesStatus = ""
    @State private var isLoadingChallenges = false
    @State private var now = Date()
    private let repository = BitterJuiceRepository()
    private let r2UploadService = R2UploadService()
    private let moods = ["🔥", "😌", "😤", "🥱", "🤩", "🧠"]

    private enum ActivityMode: String, CaseIterable, Identifiable {
        case myPicks = "My picks"
        case latest = "Latest"
        case all = "All"
        var id: String { rawValue }
    }

    private enum DurationPreset: String, CaseIterable, Identifiable {
        case min0to15 = "0–15"
        case min15to30 = "15–30"
        case min30to60 = "30–60"
        case min60plus = "60+"
        var id: String { rawValue }
        var minutes: Int {
            switch self {
            case .min0to15: return 10
            case .min15to30: return 20
            case .min30to60: return 45
            case .min60plus: return 75
            }
        }
        var subtitle: String {
            switch self {
            case .min0to15: return "quick win"
            case .min15to30: return "solid"
            case .min30to60: return "deep"
            case .min60plus: return "marathon"
            }
        }
    }

    struct ActivityItem: Hashable {
        let id: String
        let title: String
        let emoji: String
        let category: String
    }

    private let activities: [ActivityItem] = [
        // Sport (category)
        .init(id: "running", title: "Running", emoji: "🏃", category: "sport"),
        .init(id: "cycling", title: "Cycling", emoji: "🚴", category: "sport"),
        .init(id: "rollerskiing", title: "Rollerskiing", emoji: "🎿", category: "sport"),
        .init(id: "swimming", title: "Swimming", emoji: "🏊", category: "sport"),
        .init(id: "tennis", title: "Tennis", emoji: "🎾", category: "sport"),
        .init(id: "volleyball", title: "Volleyball", emoji: "🏐", category: "sport"),
        .init(id: "gym", title: "Gym", emoji: "🏋️", category: "sport"),
        .init(id: "yoga", title: "Yoga", emoji: "🧘‍♀️", category: "sport"),
        .init(id: "sport_other", title: "Other", emoji: "✨", category: "sport"),

        // Creative (category)
        .init(id: "painting", title: "Painting", emoji: "🎨", category: "creative"),
        .init(id: "drawing", title: "Drawing", emoji: "✏️", category: "creative"),
        .init(id: "playing_music", title: "Playing music", emoji: "🎵", category: "creative"),
        .init(id: "writing", title: "Writing", emoji: "📝", category: "creative"),
        .init(id: "renovations", title: "Renovations", emoji: "🛠️", category: "creative"),
        .init(id: "decoupage", title: "Decoupage", emoji: "🧩", category: "creative"),
        .init(id: "creative_other", title: "Other", emoji: "✨", category: "creative"),

        // Work (category)
        .init(id: "worked_less_than_8h", title: "Worked < 8h", emoji: "🌙", category: "work"),
        .init(id: "low_priority_tasks", title: "Low priority tasks", emoji: "🫧", category: "work"),
        .init(id: "work_other", title: "Other", emoji: "✨", category: "work"),

        // Recovery (category) — not the “top” category, but present
        .init(id: "journaling", title: "Journaling", emoji: "📓", category: "recovery"),
        .init(id: "walk", title: "Walk", emoji: "🚶", category: "recovery"),
        .init(id: "reading_book", title: "Reading book", emoji: "📖", category: "recovery"),
        .init(id: "meditation", title: "Meditation", emoji: "🧘", category: "recovery"),

        // Life / maintenance (still useful)
        .init(id: "cooking", title: "Cooking", emoji: "🍳", category: "life"),
        .init(id: "cleaning", title: "Cleaning", emoji: "🧼", category: "life"),
        .init(id: "groceries", title: "Groceries", emoji: "🛒", category: "life"),

        // Social
        .init(id: "family_time", title: "Family time", emoji: "🏡", category: "social"),
        .init(id: "hangout", title: "Hangout", emoji: "☕️", category: "social"),
        .init(id: "call", title: "Call", emoji: "📞", category: "social"),

        .init(id: "general", title: "Something else", emoji: "✨", category: "other")
    ]

    private enum Mode: String, CaseIterable, Identifiable {
        case log = "Log"
        case history = "History"
        case challenges = "Challenges"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 4)

                Group {
                    if mode == .history {
                        historyView
                    } else if mode == .challenges {
                        challengesView
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                sectionCard(title: "Pick activity") {
                                    Picker("Mode", selection: $activityMode) {
                                        ForEach(ActivityMode.allCases) { m in
                                            Text(m.rawValue).tag(m)
                                        }
                                    }
                                    .pickerStyle(.segmented)

                                    if activityMode == .latest, recentActivityIds.isEmpty {
                                        Text("Nothing here yet — once you log a few activities, your latest picks will show up.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        activityPicksGrid
                                    }

                                    Button {
                                        isActivityPickerOpen = true
                                    } label: {
                                        Label("More…", systemImage: "square.grid.2x2")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                }

                                sectionCard(title: "How did it feel?") {
                                    HStack(spacing: 12) {
                                        ForEach(moods, id: \.self) { mood in
                                            Button {
                                                selectedMood = mood
                                            } label: {
                                                Text(mood)
                                                    .font(.title2)
                                                    .padding(8)
                                                    .background(selectedMood == mood ? Color.pink.opacity(0.25) : Color.gray.opacity(0.12))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                sectionCard(title: "Duration") {
                                    HStack(spacing: 10) {
                                        ForEach(DurationPreset.allCases) { preset in
                                            let isOn = durationPreset == preset
                                            Button {
                                                durationPreset = preset
                                            } label: {
                                                VStack(spacing: 2) {
                                                    Text(preset.rawValue)
                                                        .font(.subheadline.weight(.semibold))
                                                    Text(preset.subtitle)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(isOn ? Color.pink.opacity(0.20) : Color.gray.opacity(0.10))
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                sectionCard(title: "My circles") {
                                    if isLoadingCrews {
                                        HStack(spacing: 10) {
                                            ProgressView()
                                            Text("Loading your circles…")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    } else if crews.isEmpty {
                                        Text("You’re not in a crew yet. You can still log privately — join a crew to share with friends.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("Shared by default to all your crews. Toggle off if needed.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            ForEach(crews) { crew in
                                                Toggle(crew.name, isOn: Binding(
                                                    get: { selectedCrewIds.contains(crew.id) },
                                                    set: { isOn in
                                                        if isOn { selectedCrewIds.insert(crew.id) } else { selectedCrewIds.remove(crew.id) }
                                                    }
                                                ))
                                            }
                                        }
                                    }
                                }

                                sectionCard(title: "Note (optional)") {
                                    Button {
                                        isNoteOpen = true
                                    } label: {
                                        HStack {
                                            Label(note.isEmpty ? "Add a note" : "Edit note", systemImage: "note.text")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    if !note.isEmpty {
                                        Text(note)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                sectionCard(title: "Proof & XP") {
                                    HStack {
                                        Label("Estimated XP", systemImage: "sparkles")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("\(estimatedXp)")
                                            .font(.headline)
                                    }
                                    Button {
                                        Task {
                                            do {
                                                let token = try await r2UploadService.requestUploadToken(mediaType: "proof", mimeType: "text/plain")
                                                let placeholderFile = Data("proof".utf8)
                                                try await r2UploadService.upload(data: placeholderFile, mimeType: "text/plain", token: token)
                                                proofAssetKey = token.key
                                                status = "Proof file uploaded (stored in R2) ✅"
                                            } catch {
                                                status = BitterJuiceRepository.userFacingSupabaseMessage(error)
                                            }
                                        }
                                    } label: {
                                        Label(proofAssetKey == nil ? "Upload proof file (optional)" : "Proof attached", systemImage: "paperclip.circle.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                }

                                Button {
                                    Task {
                                        do {
                                            let activityTitle = activities.first(where: { $0.id == selectedActivityId })?.title ?? selectedActivityId
                                            let composedNote = "\(selectedMood) \(activityTitle)" + (note.isEmpty ? "" : " — \(note)")
                                            try await repository.logActivity(
                                                crewIds: Array(selectedCrewIds),
                                                category: "activity",
                                                interestTagId: selectedActivityId,
                                                durationMinutes: durationPreset.minutes,
                                                note: composedNote,
                                                proofAssetKey: proofAssetKey
                                            )
                                            status = selectedCrewIds.isEmpty
                                                ? "Saved to your activity history ✅"
                                                : "Saved + shared to your crews 🚀"
                                        } catch {
                                            status = BitterJuiceRepository.userFacingSupabaseMessage(error)
                                        }
                                    }
                                } label: {
                                    Label("Log it 🚀", systemImage: "checkmark.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.pink)

                                if !status.isEmpty {
                                    Text(status)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(status.contains("✅") || status.contains("Nice") ? .green : .secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log Activity")
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.08), Color.pink.opacity(0.08), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .task {
                await refreshCrews()
                await refreshRecents()
                if mode == .history {
                    await refreshHistory()
                }
                if mode == .challenges {
                    await refreshChallenges()
                }
            }
            .onChange(of: mode) { _, newValue in
                if newValue == .history {
                    Task { await refreshHistory() }
                }
                if newValue == .challenges {
                    Task { await refreshChallenges() }
                }
            }
            .sheet(isPresented: $isActivityPickerOpen) {
                ActivityPickerSheet(
                    selectedActivityId: $selectedActivityId,
                    activities: activities
                )
            }
            .sheet(isPresented: $isNoteOpen) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Write a note…", text: $note, axis: .vertical)
                            .lineLimit(4...10)
                            .textFieldStyle(.roundedBorder)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Note")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { isNoteOpen = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $editingLog) { item in
                EditLogSheet(
                    item: item,
                    onSave: { minutes, note in
                        Task {
                            do {
                                try await repository.updateMyActivityLog(id: item.id, durationMinutes: minutes, note: note)
                                await refreshHistory()
                            } catch {
                                historyStatus = BitterJuiceRepository.userFacingSupabaseMessage(error)
                            }
                        }
                    }
                )
            }
        }
    }

    private var estimatedXp: Int {
        let base = durationPreset.minutes / 5
        return max(10, base)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var activityPicksGrid: some View {
        let items = activityItemsForMode
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.id) { item in
                let isOn = selectedActivityId == item.id
                Button {
                    selectedActivityId = item.id
                } label: {
                    HStack(spacing: 10) {
                        Text(item.emoji)
                        Text(item.title)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if isOn {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.pink)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isOn ? Color.pink.opacity(0.16) : Color.gray.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activityItemsForMode: [ActivityItem] {
        switch activityMode {
        case .myPicks:
            let ids: [String] = [
                "worked_less_than_8h",
                "walk", "reading_book", "meditation",
                "running", "gym", "yoga",
                "drawing", "playing_music",
                "cooking", "cleaning"
            ]
            let picked = ids.compactMap { id in activities.first(where: { $0.id == id }) }
            return picked
        case .latest:
            // For brand-new users this should be empty.
            guard !recentActivityIds.isEmpty else { return [] }
            let ids = Set(recentActivityIds)
            let picked = activities.filter { ids.contains($0.id) }
            return picked
        case .all:
            return activities
        }
    }

    private func refreshCrews() async {
        isLoadingCrews = true
        defer { isLoadingCrews = false }
        do {
            let list = try await repository.fetchMyJuiceCrews()
            await MainActor.run {
                crews = list
                if selectedCrewIds.isEmpty {
                    selectedCrewIds = Set(list.map(\.id)) // default: all on
                } else {
                    // keep existing selection but remove crews that no longer exist
                    selectedCrewIds = selectedCrewIds.intersection(Set(list.map(\.id)))
                }
            }
        } catch {
            await MainActor.run { crews = [] }
        }
    }

    private func refreshRecents() async {
        isLoadingRecents = true
        defer { isLoadingRecents = false }
        do {
            let rows = try await repository.fetchMyRecentActivityLogs(limit: 120)
            let latest = Array(rows.prefix(30).map(\.interestTagId))
            var counts: [String: Int] = [:]
            for row in rows {
                counts[row.interestTagId, default: 0] += 1
            }
            let top = counts
                .sorted { $0.value > $1.value }
                .prefix(20)
                .map(\.key)
            await MainActor.run {
                recentActivityIds = Array(Set(latest))
                topActivityIds = top
                if selectedActivityId.isEmpty {
                    selectedActivityId = top.first ?? latest.first ?? "general"
                }
            }
        } catch {
            await MainActor.run {
                recentActivityIds = []
                topActivityIds = []
            }
        }
    }

    private var historyView: some View {
        List {
            if isLoadingHistory {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading your logs…")
                        .foregroundStyle(.secondary)
                }
            }

            if !historyStatus.isEmpty {
                Text(historyStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(history) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(activityTitle(for: item.interestTagId))
                            .font(.headline)
                        Spacer()
                        Text(relativeDate(item.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(item.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        editingLog = item
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button(role: .destructive) {
                        Task {
                            do {
                                try await repository.deleteMyActivityLog(id: item.id)
                                await refreshHistory()
                            } catch {
                                historyStatus = BitterJuiceRepository.userFacingSupabaseMessage(error)
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func refreshHistory() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            let logs = try await repository.fetchMyActivityLogs(limit: 120)
            await MainActor.run {
                history = logs
                historyStatus = logs.isEmpty ? "No logs yet — start with a tiny win." : ""
            }
        } catch {
            await MainActor.run {
                history = []
                historyStatus = BitterJuiceRepository.userFacingSupabaseMessage(error)
            }
        }
    }

    private func activityTitle(for id: String) -> String {
        activities.first(where: { $0.id == id })?.title ?? id
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var challengesView: some View {
        List {
            if isLoadingChallenges {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading challenges…")
                        .foregroundStyle(.secondary)
                }
            }

            if !challengesStatus.isEmpty {
                Text(challengesStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(challenges) { ch in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(activityTitle(for: ch.activityPickId))
                            .font(.headline)
                        Spacer()
                        Text(ch.status.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ch.status == "accepted" ? .green : .secondary)
                    }

                    Text("\(relativeDate(ch.startAt)) → \(relativeDate(ch.endAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !ch.note.isEmpty {
                        Text(ch.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if !ch.prizeProposal.isEmpty {
                        Text("Prize: \(ch.prizeProposal)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if ch.status == "pending" {
                        HStack(spacing: 10) {
                            Button("Accept") {
                                Task { await setChallenge(ch, status: "accepted") }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Decline", role: .destructive) {
                                Task { await setChallenge(ch, status: "declined") }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await refreshChallenges()
        }
    }

    private func refreshChallenges() async {
        isLoadingChallenges = true
        defer { isLoadingChallenges = false }
        do {
            let rows = try await repository.fetchMyChallenges(limit: 80)
            await MainActor.run {
                challenges = rows
                challengesStatus = rows.isEmpty ? "No challenges yet — start one from the Crew tab." : ""
            }
        } catch {
            await MainActor.run {
                challenges = []
                challengesStatus = BitterJuiceRepository.userFacingSupabaseMessage(error)
            }
        }
    }

    private func setChallenge(_ challenge: BitterJuiceRepository.ChallengeItem, status: String) async {
        do {
            try await repository.setChallengeStatus(challengeId: challenge.id, status: status)
            await refreshChallenges()
        } catch {
            await MainActor.run {
                challengesStatus = BitterJuiceRepository.userFacingSupabaseMessage(error)
            }
        }
    }
}

private struct EditLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: BitterJuiceRepository.ActivityLogItem
    let onSave: (Int, String) -> Void
    @State private var minutes: Int
    @State private var note: String

    init(item: BitterJuiceRepository.ActivityLogItem, onSave: @escaping (Int, String) -> Void) {
        self.item = item
        self.onSave = onSave
        _minutes = State(initialValue: item.durationMinutes)
        _note = State(initialValue: item.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Duration: \(minutes) min", value: $minutes, in: 1...300)
                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(3...8)
            }
            .navigationTitle("Edit log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(minutes, note)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ActivityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedActivityId: String
    let activities: [ActivityLogView.ActivityItem]
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search…", text: $query)
                }

                ForEach(groupedCategories, id: \.title) { section in
                    Section(section.title.capitalized) {
                        ForEach(section.items, id: \.id) { item in
                            Button {
                                selectedActivityId = item.id
                                dismiss()
                            } label: {
                                HStack {
                                    Text(item.emoji)
                                    Text(item.title)
                                    Spacer()
                                    if selectedActivityId == item.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var filtered: [ActivityLogView.ActivityItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return activities }
        let lower = q.lowercased()
        return activities.filter { $0.title.lowercased().contains(lower) || $0.id.lowercased().contains(lower) }
    }

    private struct CategorySection {
        let title: String
        let items: [ActivityLogView.ActivityItem]
    }

    private var groupedCategories: [CategorySection] {
        let byCat = Dictionary(grouping: filtered, by: \.category)
        let order = ["sport", "creative", "work", "recovery", "life", "social", "other"]
        return order.compactMap { cat in
            guard let items = byCat[cat], !items.isEmpty else { return nil }
            return CategorySection(
                title: cat,
                items: items.sorted { lhs, rhs in
                    let lhsIsOther = lhs.title == "Other" || lhs.title == "Something else"
                    let rhsIsOther = rhs.title == "Other" || rhs.title == "Something else"
                    if lhsIsOther != rhsIsOther { return rhsIsOther } // non-other first
                    return lhs.title < rhs.title
                }
            )
        }
    }
}
