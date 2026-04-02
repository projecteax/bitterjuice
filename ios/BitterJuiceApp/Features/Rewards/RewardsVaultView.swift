import SwiftUI

struct RewardsVaultView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var rewards: [RewardItem] = []
    @State private var rewardTitle = ""
    @State private var rewardDescription = ""
    @State private var rewardCost = 200
    @State private var squadId = ""
    @State private var status = ""
    @State private var selectedIcon = "🏆"
    @State private var xpBalance = 0
    private let repository = BitterJuiceRepository()
    private let rewardIcons = ["🏆", "🎮", "🍿", "🧋", "🎧", "🛀", "🛍️"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    xpWalletCard
                    createRewardCard
                    rewardsListCard
                    optionalSquadCard

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
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Rewards")
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.08), Color.pink.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .task {
                try? await refreshRewards()
            }
        }
    }

    private var xpWalletCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("XP Wallet")
                    .font(.headline)
                Text("Your XP from your Supabase profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                Text("⭐️")
                    .font(.title2)
                Text("\(xpBalance)")
                    .font(.headline.monospacedDigit())
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var createRewardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create reward")
                .font(.headline)
            TextField("Title", text: $rewardTitle)
                .textFieldStyle(.roundedBorder)
            TextField("Description", text: $rewardDescription)
                .textFieldStyle(.roundedBorder)
            Stepper("Cost \(rewardCost) XP", value: $rewardCost, in: 10...5000, step: 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(rewardIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Text(icon)
                                .font(.title3)
                                .padding(8)
                                .background(selectedIcon == icon ? Color.yellow.opacity(0.28) : Color.gray.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button("Create Solo Reward") {
                Task {
                    guard let uid = sessionStore.userId else { return }
                    do {
                        try await repository.createReward(
                            ownerScope: "user",
                            ownerId: uid,
                            title: "\(selectedIcon) \(rewardTitle)",
                            description: rewardDescription,
                            costXp: rewardCost
                        )
                        status = "Reward created 🥳"
                        rewardTitle = ""
                        rewardDescription = ""
                        try await refreshRewards()
                    } catch {
                        status = BitterJuiceRepository.userFacingSupabaseMessage(error)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(rewardTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var rewardsListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available rewards")
                .font(.headline)
            if rewards.isEmpty {
                Text("No rewards yet. Add your first fun reward above.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rewards) { reward in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(reward.title)
                                .font(.headline)
                            Spacer()
                            Text("\(reward.costXp) XP")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.22))
                                .clipShape(Capsule())
                        }
                        Text(reward.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Unlock this reward") {
                            Task {
                                do {
                                    let optionalSquad = squadId.isEmpty ? nil : squadId
                                    try await repository.purchaseReward(rewardId: reward.id, squadId: optionalSquad)
                                    status = "Purchased 🎉"
                                } catch {
                                    status = "Purchase endpoint pending: \(BitterJuiceRepository.userFacingSupabaseMessage(error))"
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var optionalSquadCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share purchases to squad")
                .font(.headline)
            TextField("Crew ID (optional)", text: $squadId)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func refreshRewards() async throws {
        guard let uid = sessionStore.userId else { return }
        rewards = try await repository.fetchRewards(for: uid)
        if let stats = try await repository.fetchProfileSnapshot(userId: uid) {
            await MainActor.run { xpBalance = stats.xpBalance }
        }
    }
}
