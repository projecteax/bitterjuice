import SwiftUI

struct ActivityLogView: View {
    @State private var category = "work"
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
    private let repository = BitterJuiceRepository()
    private let r2UploadService = R2UploadService()
    private let categories: [(String, String)] = [
        ("work", "💼"),
        ("rest", "🛋️"),
        ("mental", "🧠"),
        ("physical", "🏃"),
        ("social", "🫂"),
        ("survival", "🧃")
    ]
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
        // Work
        .init(id: "deep_work", title: "Deep work", emoji: "🎯", category: "work"),
        .init(id: "emails", title: "Emails", emoji: "📧", category: "work"),
        .init(id: "admin", title: "Admin", emoji: "🗂️", category: "work"),
        .init(id: "meeting", title: "Meeting", emoji: "🗣️", category: "work"),
        .init(id: "study", title: "Study", emoji: "📚", category: "work"),
        // Rest
        .init(id: "nap", title: "Nap", emoji: "😴", category: "rest"),
        .init(id: "relax", title: "Relax", emoji: "🛋️", category: "rest"),
        .init(id: "walk", title: "Walk", emoji: "🚶", category: "rest"),
        // Mental
        .init(id: "journaling", title: "Journaling", emoji: "📓", category: "mental"),
        .init(id: "meditation", title: "Meditation", emoji: "🧘", category: "mental"),
        .init(id: "therapy", title: "Therapy", emoji: "🫶", category: "mental"),
        // Physical
        .init(id: "sport", title: "Sport", emoji: "🏃", category: "physical"),
        .init(id: "gym", title: "Strength", emoji: "🏋️", category: "physical"),
        .init(id: "yoga", title: "Yoga", emoji: "🧘‍♀️", category: "physical"),
        .init(id: "cycling", title: "Cycling", emoji: "🚴", category: "physical"),
        // Social
        .init(id: "family_time", title: "Family time", emoji: "🏡", category: "social"),
        .init(id: "hangout", title: "Hangout", emoji: "☕️", category: "social"),
        .init(id: "call", title: "Call", emoji: "📞", category: "social"),
        // Survival
        .init(id: "cooking", title: "Cooking", emoji: "🍳", category: "survival"),
        .init(id: "cleaning", title: "Cleaning", emoji: "🧼", category: "survival"),
        .init(id: "groceries", title: "Groceries", emoji: "🛒", category: "survival"),
        .init(id: "general", title: "Something else", emoji: "✨", category: "work")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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

                    sectionCard(title: "What did you do?") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                            ForEach(categories, id: \.0) { item in
                                Button {
                                    category = item.0
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(item.1).font(.title3)
                                        Text(item.0.capitalized).font(.caption.weight(.semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(category == item.0 ? Color.purple.opacity(0.22) : Color.gray.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    sectionCard(title: "Pick activity") {
                        Picker("Mode", selection: $activityMode) {
                            ForEach(ActivityMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        activityPicksGrid

                        Button {
                            isActivityPickerOpen = true
                        } label: {
                            Label("More…", systemImage: "square.grid.2x2")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
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
                                    category: category,
                                    interestTagId: selectedActivityId,
                                    durationMinutes: durationPreset.minutes,
                                    note: composedNote,
                                    proofAssetKey: proofAssetKey
                                )
                                if selectedCrewIds.isEmpty {
                                    status = "Saved to your activity history ✅"
                                } else {
                                    status = "Saved + shared to your crews 🚀"
                                }
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
            }
            .sheet(isPresented: $isActivityPickerOpen) {
                ActivityPickerSheet(
                    category: $category,
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
        let items = activityItemsForMode.filter { $0.category == category }
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
            let ids = Set(topActivityIds)
            let picked = activities.filter { ids.contains($0.id) }
            return picked.isEmpty ? activities : picked
        case .latest:
            let ids = Set(recentActivityIds)
            let picked = activities.filter { ids.contains($0.id) }
            return picked.isEmpty ? activities : picked
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
}

private struct ActivityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var category: String
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
                                category = item.category
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
        let order = ["work", "physical", "mental", "rest", "social", "survival"]
        return order.compactMap { cat in
            guard let items = byCat[cat], !items.isEmpty else { return nil }
            return CategorySection(title: cat, items: items.sorted { $0.title < $1.title })
        }
    }
}
