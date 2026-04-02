import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var username = ""
    @Published var selectedGoals: [String] = ["getting_out_of_slump"]
    @Published var tags: [String] = ["Drawing"]
    @Published var customTag = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    func addTag() {
        let trimmed = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !tags.contains(trimmed) {
            tags.append(trimmed)
        }
        customTag = ""
    }

    func toggleGoal(_ goalId: String) {
        if selectedGoals.contains(goalId) {
            selectedGoals.removeAll { $0 == goalId }
        } else {
            selectedGoals.append(goalId)
        }
    }

    func completeOnboarding() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await ProfileSyncService.completeOnboarding(
                username: username,
                primaryGoal: selectedGoals.first ?? "getting_out_of_slump",
                goals: selectedGoals.isEmpty ? ["getting_out_of_slump"] : selectedGoals,
                timezone: TimeZone.current.identifier,
                interestTags: tags
            )
            return true
        } catch {
            errorMessage = BitterJuiceRepository.userFacingSupabaseMessage(error)
            return false
        }
    }
}
