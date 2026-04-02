import Foundation
import Supabase

enum ProfileSyncService {
    struct ProfileUpsert: Encodable {
        let id: UUID
        let username: String
        let primary_goal: String
        let timezone: String
        let onboarding_status: String
        let updated_at: String
    }

    struct TagInsert: Encodable {
        let user_id: UUID
        let name: String
        let source: String
    }

    struct GoalInsert: Encodable {
        let user_id: UUID
        let goal_id: String
        let source: String
    }

    /// Zapis profilu + tagi po rejestracji / onboarding.
    static func completeOnboarding(
        username: String,
        primaryGoal: String,
        goals: [String],
        timezone: String,
        interestTags: [String]
    ) async throws {
        let client = SupabaseClientProvider.shared
        let session = try await client.auth.session
        let uid = session.user.id

        let now = ISO8601DateFormatter().string(from: Date())
        let profile = ProfileUpsert(
            id: uid,
            username: username,
            primary_goal: primaryGoal,
            timezone: timezone,
            onboarding_status: "complete",
            updated_at: now
        )

        try await client
            .from("profiles")
            .upsert(profile, onConflict: "id")
            .execute()

        // Goals (multi-select) stored per-user (not global suggestions).
        try await client
            .from("user_goals")
            .delete()
            .eq("user_id", value: uid.uuidString)
            .execute()

        let goalRows = Array(Set(goals)).map { GoalInsert(user_id: uid, goal_id: $0, source: "onboarding") }
        if !goalRows.isEmpty {
            try await client
                .from("user_goals")
                .insert(goalRows)
                .execute()
        }

        try await client
            .from("user_interest_tags")
            .delete()
            .eq("user_id", value: uid.uuidString)
            .execute()

        let tagRows = Array(Set(interestTags)).map { TagInsert(user_id: uid, name: $0, source: "onboarding") }
        if !tagRows.isEmpty {
            try await client
                .from("user_interest_tags")
                .insert(tagRows)
                .execute()
        }
    }
}
