import SwiftUI

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case goal
    case interests
    case username
    case account
}

private enum AccountMode: String, CaseIterable, Identifiable {
    case create
    case login

    var id: String { rawValue }
}

struct OnboardingEntryView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var authService = AuthService()

    @State private var step: OnboardingStep = .welcome
    @State private var email = ""
    @State private var password = ""
    @State private var authMessage: String?
    @State private var accountMode: AccountMode = .create

    @State private var isOtherTagsOpen = false
    @State private var otherTagsQuery = ""

    private let topTagPicks: [String] = [
        "Sport", "Walking", "Running", "Yoga",
        "Reading", "Journaling", "Music", "Drawing",
        "Cooking", "Meditation", "Gaming", "Learning languages"
    ]

    private let tagCategories: [(title: String, tags: [String])] = [
        ("Movement", ["Sport", "Walking", "Running", "Cycling", "Swimming", "Yoga", "Pilates", "Strength training", "Stretching", "Climbing", "Martial arts", "Team sports", "Dancing", "Hiking"]),
        ("Mind & learning", ["Reading", "Audiobooks", "Writing", "Journaling", "Learning languages", "Coding", "Studying", "Podcasts", "Chess", "Puzzles"]),
        ("Creative", ["Drawing", "Painting", "Photography", "Video editing", "Music", "Singing", "Guitar", "Piano", "Crafts", "DIY projects"]),
        ("Calm & recovery", ["Meditation", "Breathing", "Nature", "Sleep routine", "Relaxing", "Sauna", "Cold shower", "Tea time", "Quiet time", "Digital detox"]),
        ("Home & life", ["Cooking", "Baking", "Meal prep", "Cleaning", "Decluttering", "Gardening", "Home projects", "Budgeting", "Planning"]),
        ("Social & community", ["Family time", "Quality time", "Volunteering", "Meetups", "Networking"]),
        ("Fun & leisure", ["Gaming", "Movies", "Series", "Board games", "Travel", "Exploring the city", "Museums", "Coffee", "Reading in cafés"]),
        ("Work & growth", ["Deep work", "Career growth", "Side project", "Portfolio"])
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.08, blue: 0.18),
                    Color(red: 0.18, green: 0.12, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                Group {
                    switch step {
                    case .welcome: welcomePage
                    case .goal: goalPage
                    case .interests: interestsPage
                    case .username: usernamePage
                    case .account: accountPage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
        .tint(Color(red: 0.95, green: 0.55, blue: 0.35))
    }

    @ViewBuilder
    private var progressBar: some View {
        if accountMode == .login, step == .account {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Login")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("1/1")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.45, blue: 0.35),
                                Color(red: 0.75, green: 0.35, blue: 0.65)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        } else {
            let idx = OnboardingStep.allCases.firstIndex(of: step) ?? 0
            let total = CGFloat(OnboardingStep.allCases.count)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(stepTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("\(idx + 1)/\(OnboardingStep.allCases.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.45, blue: 0.35),
                                        Color(red: 0.75, green: 0.35, blue: 0.65)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(idx + 1) / total)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case .welcome: return "Start"
        case .goal: return "Your focus"
        case .interests: return "Interests"
        case .username: return "Name"
        case .account: return "Account"
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            Text("BitterJuice")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Turn small wins into momentum — without the toxic grind.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 28)

            VStack(alignment: .leading, spacing: 12) {
                labelRow("Micro-wins that fit real mental health days")
                labelRow("Crews that cheer, nudge, and keep it human")
                labelRow("Rewards you actually care about")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 32)

            Spacer()
            VStack(spacing: 12) {
                primaryButton("Continue") {
                    accountMode = .create
                    step = .goal
                }
                secondaryButton("I already have an account") {
                    Task {
                        await prepareLoginMode()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func labelRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.55))
            Text(text)
        }
    }

    private var goalPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What do you want to move toward?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)

            Text("Pick a few — you can change this later.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(goalChoices, id: \.id) { item in
                        goalCard(item)
                    }
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 16) {
                secondaryButton("Back") { step = .welcome }
                primaryButton("Next") { step = .interests }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private struct GoalChoice: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let symbol: String
    }

    private var goalChoices: [GoalChoice] {
        [
            .init(id: "overcoming_workaholism", title: "Ease off the hustle", subtitle: "Rest and boundaries count as progress", symbol: "moon.zzz.fill"),
            .init(id: "getting_out_of_slump", title: "Get out of a slump", subtitle: "Gentle structure, no shame", symbol: "sun.max.fill"),
            .init(id: "socializing_more", title: "Show up socially", subtitle: "Small connections, consistently", symbol: "person.3.fill"),
            .init(id: "better_routine", title: "Steadier routine", subtitle: "Tiny habits that stick", symbol: "calendar"),
            .init(id: "mental_reset", title: "Mental reset", subtitle: "Mood, energy, clarity", symbol: "brain.head.profile"),
            .init(id: "fitness", title: "Build strength & stamina", subtitle: "Move more, feel better", symbol: "figure.run"),
            .init(id: "focus", title: "Focus & productivity", subtitle: "Less chaos, more done", symbol: "scope"),
            .init(id: "confidence", title: "Confidence", subtitle: "Small wins you can trust", symbol: "sparkles"),
            .init(id: "sleep", title: "Sleep", subtitle: "Recover and recharge", symbol: "bed.double.fill"),
            .init(id: "nutrition", title: "Nutrition", subtitle: "Eat in a way that supports you", symbol: "fork.knife"),
            .init(id: "stress", title: "Lower stress", subtitle: "More calm, fewer spikes", symbol: "waveform.path.ecg"),
            .init(id: "creativity", title: "Creativity", subtitle: "Make and play again", symbol: "paintbrush.pointed.fill"),
            .init(id: "learning", title: "Learn something", subtitle: "Skills, curiosity, growth", symbol: "graduationcap.fill")
        ]
    }

    private func goalCard(_ item: GoalChoice) -> some View {
        let selected = viewModel.selectedGoals.contains(item.id)
        return Button {
            viewModel.toggleGoal(item.id)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.symbol)
                    .font(.title2)
                    .frame(width: 36)
                    .foregroundStyle(selected ? Color(red: 1, green: 0.55, blue: 0.4) : .white.opacity(0.5))
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.45, green: 0.9, blue: 0.55))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.14) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selected ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var interestsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What do you actually like doing?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)

            Text("Tap presets or add your own. You can change this later.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            Text("Top picks")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 20)

            FlowTagLayout(tags: topTagPicks, selectedTags: viewModel.tags) { tag in
                viewModel.togglePreset(tag)
            }
            .padding(.horizontal, 20)

            Button {
                otherTagsQuery = ""
                isOtherTagsOpen = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                    Text("Other…")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .opacity(0.85)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)

            Text("Can’t find yours? Add it — it’s private to your account.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 20)

            TextField("Add a custom tag…", text: $viewModel.customTag)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .onSubmit { viewModel.addTag() }

            Button("Add tag") { viewModel.addTag() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.45))
                .padding(.horizontal, 20)

            if !viewModel.tags.isEmpty {
                Text(viewModel.tags.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.horizontal, 20)
            }

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                secondaryButton("Back") { step = .goal }
                primaryButton("Next") {
                    if viewModel.tags.isEmpty {
                        viewModel.tags = ["General"]
                    }
                    step = .username
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $isOtherTagsOpen) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Search tags…", text: $otherTagsQuery)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        ForEach(filteredTagCategories, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary.opacity(0.9))
                                    .padding(.horizontal, 16)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                                    ForEach(section.tags, id: \.self) { tag in
                                        let isOn = viewModel.tags.contains(tag)
                                        Button {
                                            viewModel.togglePreset(tag)
                                        } label: {
                                            Text(tag)
                                                .font(.subheadline.weight(.medium))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .fill(isOn ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.10))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .strokeBorder(isOn ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1)
                                                )
                                                .foregroundStyle(.primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 6)
                        }

                        Spacer(minLength: 24)
                    }
                }
                .navigationTitle("Pick tags")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { isOtherTagsOpen = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var filteredTagCategories: [(title: String, tags: [String])] {
        let q = otherTagsQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return tagCategories }
        let lower = q.lowercased()
        return tagCategories.compactMap { section in
            let filtered = section.tags.filter { $0.lowercased().contains(lower) }
            if filtered.isEmpty { return nil }
            return (title: section.title, tags: filtered)
        }
    }

    private var usernamePage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How should your crew see you?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)

            TextField("Display name", text: $viewModel.username)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                secondaryButton("Back") { step = .interests }
                primaryButton("Next") {
                    if viewModel.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.username = "Player"
                    }
                    accountMode = .create
                    step = .account
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private var accountPage: some View {
        VStack(spacing: 20) {
            if accountMode == .login {
                Text("Log in to your account")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                if let authMessage {
                    Text(authMessage)
                        .font(.caption)
                        .foregroundStyle(authMessage.contains("Welcome") ? Color.green : Color.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                primaryButton(viewModel.isSaving ? "Logging in…" : "Log in") {
                    Task { await finishOnboarding(createAccount: false) }
                }
                .disabled(viewModel.isSaving || email.isEmpty || password.isEmpty)
            } else if !sessionStore.isAuthenticated {
                Picker("Account mode", selection: $accountMode) {
                    Text("Create").tag(AccountMode.create)
                    Text("Log in").tag(AccountMode.login)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                Text(accountMode == .create ? "Create an account to save progress" : "Log in to your existing account")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                SecureField("Password (min 6 characters)", text: $password)
                    .textContentType(.newPassword)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                if let authMessage {
                    Text(authMessage)
                        .font(.caption)
                        .foregroundStyle(authMessage.contains("Saved") || authMessage.contains("ready") ? Color.green : Color.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                primaryButton(
                    viewModel.isSaving
                        ? "Saving…"
                        : (accountMode == .create ? "Create account & finish" : "Log in & continue")
                ) {
                    Task { await finishOnboarding(createAccount: accountMode == .create) }
                }
                .disabled(viewModel.isSaving || email.isEmpty || password.count < 6)
            } else {
                Text("You're signed in. Save your profile to enter the app.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 20)

                if let authMessage {
                    Text(authMessage)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                primaryButton(viewModel.isSaving ? "Saving…" : "Save profile & enter") {
                    Task { await finishOnboarding(createAccount: false) }
                }
                .disabled(viewModel.isSaving)
            }

            secondaryButton("Back") { step = .username }
                .padding(.top, 8)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 20)
        }
        .padding(.top, 24)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.42, blue: 0.38),
                            Color(red: 0.75, green: 0.35, blue: 0.55)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(.plain)
    }

    private func finishOnboarding(createAccount: Bool) async {
        viewModel.errorMessage = nil
        authMessage = nil
        let client = SupabaseClientProvider.shared
        do {
            if accountMode == .login {
                // Always authenticate with entered credentials. Do not reuse stale signed-in user.
                if sessionStore.isAuthenticated {
                    try? await authService.signOut()
                }
                try await authService.signInWithEmail(email: email, password: password)
                let session = try await client.auth.session
                sessionStore.finishReturningUserLogin(session: session)
                authMessage = "Welcome back. You're in."
                return
            }

            if createAccount {
                try await authService.createAccountWithEmail(email: email, password: password)
                authMessage = "Account created."
            }

            let ok = await viewModel.completeOnboarding()
            if ok {
                let session = try await client.auth.session
                sessionStore.finishReturningUserLogin(session: session)
                authMessage = "You're in."
            }
        } catch {
            authMessage = BitterJuiceRepository.userFacingSupabaseMessage(error)
        }
    }

    @MainActor
    private func prepareLoginMode() async {
        accountMode = .login
        authMessage = nil
        viewModel.errorMessage = nil
        step = .account
        if sessionStore.isAuthenticated {
            try? await authService.signOut()
        }
    }
}

// MARK: - Tag chips (simple flow layout)

private struct FlowTagLayout: View {
    let tags: [String]
    let selectedTags: [String]
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                let isOn = selectedTags.contains(tag)
                Button {
                    onTap(tag)
                } label: {
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isOn ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                        )
                        .foregroundStyle(.white)
                        .overlay(
                            Capsule().strokeBorder(isOn ? Color.white.opacity(0.45) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension OnboardingViewModel {
    fileprivate func togglePreset(_ tag: String) {
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
    }
}
