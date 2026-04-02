import Foundation
import Supabase

struct FeedEventItem: Identifiable {
    let id: String
    let eventType: String
    let actorUserId: String
    let createdAt: Date
    let payload: [String: Any]
}

struct PublicProfileItem: Identifiable, Sendable {
    let id: String
    let username: String
    let avatarKey: String?
}

struct RewardItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let costXp: Int
}

/// A motivation group (“Juice Crew”) — same id as `feed_events.squad_id`.
struct JuiceCrewItem: Identifiable, Hashable {
    let id: String
    let name: String
}

struct ProfileSnapshot: Sendable {
    let username: String
    let xpBalance: Int
    let level: Int
    let streakDays: Int
}

final class BitterJuiceRepository {
    private let client = SupabaseClientProvider.shared

    struct CalibrationUpsert: Encodable {
        let user_id: UUID
        let date_key: String
        let battery: Double
        let head: Double
        let stress: Double
        let low_energy: Bool
        let generated_theme: String
        let submitted_at: String
    }

    struct RewardRow: Decodable {
        let id: UUID
        let title: String
        let description: String
        let cost_xp: Int
    }

    private struct FeedEventRow: Decodable {
        let id: UUID
        let squad_id: UUID
        let actor_id: UUID
        let event_type: String
        let created_at: Date
        let payload: JSONObject?
    }

    private struct ActivityPayload: Encodable {
        let category: String
        let interest_tag_id: String
        let duration_minutes: Int
        let note: String
        let low_energy: Bool
        let proof_asset_key: String?
        let quantity_value: Double?
        let quantity_unit: String?
    }

    private struct FeedEventInsert: Encodable {
        let squad_id: UUID
        let actor_id: UUID
        let event_type: String
        let payload: ActivityPayload
    }

    private struct ActivityLogInsert: Encodable {
        let user_id: UUID
        let category: String
        let interest_tag_id: String
        let duration_minutes: Int
        let note: String
        let low_energy: Bool
        let proof_asset_key: String?
        let quantity_value: Double?
        let quantity_unit: String?
        let posted_to_squad_feed: Bool
        let squad_id: UUID?
    }

    private struct ActivityLogRow: Decodable {
        let id: UUID
        let created_at: Date
        let category: String
        let interest_tag_id: String
        let duration_minutes: Int
        let note: String
        let proof_asset_key: String?
        let quantity_value: Double?
        let quantity_unit: String?
    }

    private struct ProfileStatsRow: Decodable {
        let username: String
        let xp_balance: Int
        let level: Int
        let streak_days: Int
    }

    private struct PublicProfileRow: Decodable {
        let id: UUID
        let username: String
        let avatar_key: String?
    }

    func publicAvatarURL(for avatarKey: String) -> URL? {
        guard !avatarKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        // For public buckets: https://<ref>.supabase.co/storage/v1/object/public/<bucket>/<path>
        return try? client.storage.from("avatars").getPublicURL(path: avatarKey)
    }

    func uploadMyAvatar(imageData: Data, fileExtension: String) async throws -> String {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        let uid = session.user.id.uuidString
        let ext = fileExtension.lowercased().replacingOccurrences(of: ".", with: "")
        let key = "\(uid)/avatar.\(ext.isEmpty ? "jpg" : ext)"

        // Upload (overwrite) to Storage
        _ = try await client.storage
            .from("avatars")
            .upload(
                key,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: ext == "png" ? "image/png" : "image/jpeg",
                    upsert: true
                )
            )

        // Save reference on profile
        struct AvatarUpdate: Encodable { let avatar_key: String }
        try await client
            .from("profiles")
            .update(AvatarUpdate(avatar_key: key))
            .eq("id", value: uid)
            .execute()

        return key
    }

    private struct FeedReactionInsert: Encodable {
        let feed_event_id: UUID
        let user_id: UUID
        let reaction_type: String
    }

    private struct SquadInsert: Encodable {
        let name: String
        let created_by: UUID
    }

    private struct SquadIdRow: Decodable {
        let id: UUID
    }

    private struct SquadListRow: Decodable {
        let id: UUID
        let name: String
    }

    private struct SquadMemberRow: Encodable {
        let squad_id: UUID
        let user_id: UUID
        let role: String
    }

    private struct SquadMemberLookup: Decodable {
        let squad_id: UUID
    }

    // MARK: - Challenges

    struct ChallengeItem: Identifiable, Sendable {
        let id: String
        let createdAt: Date
        let createdBy: String
        let inviteeId: String
        let crewId: String?
        let status: String
        let activityPickId: String
        let goalMetric: String
        let targetValue: Double
        let targetUnit: String
        let startAt: Date
        let endAt: Date
        let prizeProposal: String
        let note: String
    }

    private struct ChallengeRow: Decodable {
        let id: UUID
        let created_at: Date
        let created_by: UUID
        let invitee_id: UUID
        let crew_id: UUID?
        let status: String
        let activity_pick_id: String
        let goal_metric: String?
        let target_value: Double?
        let target_unit: String?
        let goal_target: Int?
        let start_at: Date
        let end_at: Date
        let prize_proposal: String
        let note: String
    }

    private struct ChallengeInsert: Encodable {
        let created_by: UUID
        let invitee_id: UUID
        let crew_id: UUID?
        let status: String
        let activity_pick_id: String
        let goal_metric: String
        let target_value: Double
        let target_unit: String
        let start_at: Date
        let end_at: Date
        let prize_proposal: String
        let note: String
    }

    private struct ChallengeStatusUpdate: Encodable {
        let status: String
    }

    func fetchMyChallenges(limit: Int = 50) async throws -> [ChallengeItem] {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        let uid = session.user.id.uuidString

        // Fetch where I'm creator OR invitee
        let rows: [ChallengeRow] = try await client
            .from("challenges")
            .select()
            .or("created_by.eq.\(uid),invitee_id.eq.\(uid)")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows.map {
            let metric = $0.goal_metric ?? "sessions"
            let target = $0.target_value ?? Double($0.goal_target ?? 1)
            let unit = $0.target_unit ?? (metric == "distance" ? "km" : metric)
            return ChallengeItem(
                id: $0.id.uuidString,
                createdAt: $0.created_at,
                createdBy: $0.created_by.uuidString,
                inviteeId: $0.invitee_id.uuidString,
                crewId: $0.crew_id?.uuidString,
                status: $0.status,
                activityPickId: $0.activity_pick_id,
                goalMetric: metric,
                targetValue: target,
                targetUnit: unit,
                startAt: $0.start_at,
                endAt: $0.end_at,
                prizeProposal: $0.prize_proposal,
                note: $0.note
            )
        }
    }

    func createChallenge(
        inviteeId: String,
        crewId: String?,
        activityPickId: String,
        goalMetric: String,
        targetValue: Double,
        targetUnit: String,
        startAt: Date,
        endAt: Date,
        prizeProposal: String,
        note: String
    ) async throws {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        guard let inviteeUUID = UUID(uuidString: inviteeId) else {
            throw NSError(domain: "BitterJuice", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid invitee id."])
        }
        let crewUUID = crewId.flatMap(UUID.init(uuidString:))
        let row = ChallengeInsert(
            created_by: session.user.id,
            invitee_id: inviteeUUID,
            crew_id: crewUUID,
            status: "pending",
            activity_pick_id: activityPickId,
            goal_metric: goalMetric,
            target_value: max(0.0001, targetValue),
            target_unit: targetUnit,
            start_at: startAt,
            end_at: endAt,
            prize_proposal: prizeProposal,
            note: note
        )
        try await client.from("challenges").insert(row).execute()
    }

    func fetchCrewMemberProfiles(crewId: String) async throws -> [PublicProfileItem] {
        guard let crewUUID = UUID(uuidString: crewId) else { return [] }
        struct MemberRow: Decodable { let user_id: UUID }
        let members: [MemberRow] = try await client
            .from("squad_members")
            .select("user_id")
            .eq("squad_id", value: crewUUID.uuidString)
            .execute()
            .value
        return try await fetchPublicProfiles(userIds: members.map { $0.user_id.uuidString })
    }

    func computeChallengeProgress(
        userId: String,
        activityPickId: String,
        startAt: Date,
        endAt: Date,
        metric: String
    ) async throws -> Double {
        let startIso = ISO8601DateFormatter().string(from: startAt)
        let endIso = ISO8601DateFormatter().string(from: endAt)
        let rows: [ActivityLogRow] = try await client
            .from("activity_logs")
            .select("id,created_at,category,interest_tag_id,duration_minutes,note,proof_asset_key,quantity_value,quantity_unit")
            .eq("user_id", value: userId)
            .eq("interest_tag_id", value: activityPickId)
            .gte("created_at", value: startIso)
            .lte("created_at", value: endIso)
            .execute()
            .value

        switch metric {
        case "minutes":
            return Double(rows.map(\.duration_minutes).reduce(0, +))
        case "distance":
            return rows.compactMap { row in
                guard let v = row.quantity_value, row.quantity_unit?.lowercased() == "km" else { return nil }
                return v
            }.reduce(0, +)
        default:
            return Double(rows.count)
        }
    }

    func setChallengeStatus(challengeId: String, status: String) async throws {
        try await client
            .from("challenges")
            .update(ChallengeStatusUpdate(status: status))
            .eq("id", value: challengeId)
            .execute()
    }

    func saveDailyCalibration(
        userId: String,
        battery: Double,
        head: Double,
        stress: Double,
        lowEnergyMode: Bool
    ) async throws {
        guard let uid = UUID(uuidString: userId) else { return }
        let dateKey = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        let row = CalibrationUpsert(
            user_id: uid,
            date_key: dateKey,
            battery: battery,
            head: head,
            stress: stress,
            low_energy: lowEnergyMode,
            generated_theme: "auto",
            submitted_at: ISO8601DateFormatter().string(from: Date())
        )
        try await client
            .from("daily_calibrations")
            .upsert(row, onConflict: "user_id,date_key")
            .execute()
    }

    /// Saves a row in `activity_logs` every time. Inserts into `feed_events` only when
    /// `shareToSquadFeed` is true and `squadId` is a valid UUID (your Juice Crew id).
    func logActivity(
        shareToSquadFeed: Bool,
        squadId: String,
        category: String,
        interestTagId: String,
        durationMinutes: Int,
        note: String,
        proofAssetKey: String?,
        lowEnergyMode: Bool,
        quantityValue: Double? = nil,
        quantityUnit: String? = nil
    ) async throws {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        let trimmedSquad = squadId.trimmingCharacters(in: .whitespacesAndNewlines)
        let squadUUID = UUID(uuidString: trimmedSquad)
        if shareToSquadFeed, squadUUID == nil {
            throw NSError(
                domain: "BitterJuice",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Paste a valid Crew ID to post to the feed, or turn off “Share to Juice Crew feed”."]
            )
        }

        let payload = ActivityPayload(
            category: category,
            interest_tag_id: interestTagId,
            duration_minutes: durationMinutes,
            note: note,
            low_energy: lowEnergyMode,
            proof_asset_key: proofAssetKey,
            quantity_value: quantityValue,
            quantity_unit: quantityUnit
        )

        var postedToFeed = false
        if shareToSquadFeed, let squadUUID {
            let feedRow = FeedEventInsert(
                squad_id: squadUUID,
                actor_id: session.user.id,
                event_type: "activity_logged",
                payload: payload
            )
            try await client.from("feed_events").insert(feedRow).execute()
            postedToFeed = true
        }

        let logRow = ActivityLogInsert(
            user_id: session.user.id,
            category: category,
            interest_tag_id: interestTagId,
            duration_minutes: durationMinutes,
            note: note,
            low_energy: lowEnergyMode,
            proof_asset_key: proofAssetKey,
            quantity_value: quantityValue,
            quantity_unit: quantityUnit,
            posted_to_squad_feed: postedToFeed,
            squad_id: squadUUID
        )
        try await client.from("activity_logs").insert(logRow).execute()
    }

    /// New: log once, optionally post to multiple crews (circles).
    func logActivity(
        crewIds: [String],
        category: String,
        interestTagId: String,
        durationMinutes: Int,
        note: String,
        proofAssetKey: String?,
        quantityValue: Double? = nil,
        quantityUnit: String? = nil
    ) async throws {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }

        let normalizedCrewUUIDs: [UUID] = crewIds
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(UUID.init(uuidString:))

        let payload = ActivityPayload(
            category: category,
            interest_tag_id: interestTagId,
            duration_minutes: durationMinutes,
            note: note,
            low_energy: false,
            proof_asset_key: proofAssetKey,
            quantity_value: quantityValue,
            quantity_unit: quantityUnit
        )

        for crewId in normalizedCrewUUIDs {
            let feedRow = FeedEventInsert(
                squad_id: crewId,
                actor_id: session.user.id,
                event_type: "activity_logged",
                payload: payload
            )
            try await client.from("feed_events").insert(feedRow).execute()
        }

        let logRow = ActivityLogInsert(
            user_id: session.user.id,
            category: category,
            interest_tag_id: interestTagId,
            duration_minutes: durationMinutes,
            note: note,
            low_energy: false,
            proof_asset_key: proofAssetKey,
            quantity_value: quantityValue,
            quantity_unit: quantityUnit,
            posted_to_squad_feed: !normalizedCrewUUIDs.isEmpty,
            squad_id: normalizedCrewUUIDs.first
        )
        try await client.from("activity_logs").insert(logRow).execute()
    }

    func fetchMyRecentActivityLogs(limit: Int = 80) async throws -> [(category: String, interestTagId: String, createdAt: Date)] {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        let rows: [ActivityLogRow] = try await client
            .from("activity_logs")
            .select("id,created_at,category,interest_tag_id,duration_minutes,note,proof_asset_key,quantity_value,quantity_unit")
            .eq("user_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.map { ($0.category, $0.interest_tag_id, $0.created_at) }
    }

    struct ActivityLogItem: Identifiable, Sendable {
        let id: String
        let createdAt: Date
        let interestTagId: String
        let durationMinutes: Int
        let note: String
        let proofAssetKey: String?
    }

    func fetchMyActivityLogs(limit: Int = 100) async throws -> [ActivityLogItem] {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        let rows: [ActivityLogRow] = try await client
            .from("activity_logs")
            .select("id,created_at,category,interest_tag_id,duration_minutes,note,proof_asset_key")
            .eq("user_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.map {
            ActivityLogItem(
                id: $0.id.uuidString,
                createdAt: $0.created_at,
                interestTagId: $0.interest_tag_id,
                durationMinutes: $0.duration_minutes,
                note: $0.note,
                proofAssetKey: $0.proof_asset_key
            )
        }
    }

    func updateMyActivityLog(id: String, durationMinutes: Int, note: String) async throws {
        struct UpdateRow: Encodable {
            let duration_minutes: Int
            let note: String
        }
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        try await client
            .from("activity_logs")
            .update(UpdateRow(duration_minutes: durationMinutes, note: note))
            .eq("id", value: id)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
    }

    func deleteMyActivityLog(id: String) async throws {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Session expired — sign in again."])
        }
        try await client
            .from("activity_logs")
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
    }

    func fetchProfileSnapshot(userId: String) async throws -> ProfileSnapshot? {
        let rows: [ProfileStatsRow] = try await client
            .from("profiles")
            .select("username,xp_balance,level,streak_days")
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else { return nil }
        return ProfileSnapshot(
            username: row.username,
            xpBalance: row.xp_balance,
            level: row.level,
            streakDays: row.streak_days
        )
    }

    func fetchFeedEvents(for squadId: String) async throws -> [FeedEventItem] {
        let trimmed = squadId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let squadUUID = UUID(uuidString: trimmed) else {
            throw NSError(
                domain: "BitterJuice",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Wpisz prawidłowy Squad ID (format UUID)."]
            )
        }
        let rows: [FeedEventRow] = try await client
            .from("feed_events")
            .select()
            .eq("squad_id", value: squadUUID.uuidString)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        return rows.map { row in
            FeedEventItem(
                id: row.id.uuidString,
                eventType: row.event_type,
                actorUserId: row.actor_id.uuidString,
                createdAt: row.created_at,
                payload: Self.payloadToDict(row.payload)
            )
        }
    }

    func fetchPublicProfiles(userIds: [String]) async throws -> [PublicProfileItem] {
        let unique = Array(Set(userIds)).filter { UUID(uuidString: $0) != nil }
        guard !unique.isEmpty else { return [] }
        let rows: [PublicProfileRow] = try await client
            .from("profiles")
            .select("id,username,avatar_key")
            .in("id", values: unique.map { $0 as any PostgrestFilterValue })
            .execute()
            .value
        return rows.map { PublicProfileItem(id: $0.id.uuidString, username: $0.username, avatarKey: $0.avatar_key) }
    }

    func sendReaction(feedEventId: String, reaction: String) async throws {
        guard let eventUUID = UUID(uuidString: feedEventId) else {
            throw NSError(domain: "BitterJuice", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nieprawidłowy wpis."])
        }
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Sesja wygasła — zaloguj się ponownie."])
        }
        let normalized = Self.normalizeReaction(reaction)
        let row = FeedReactionInsert(
            feed_event_id: eventUUID,
            user_id: session.user.id,
            reaction_type: normalized
        )
        try await client.from("feed_reactions").upsert(row, onConflict: "feed_event_id,user_id,reaction_type").execute()
    }

    func createReward(ownerScope: String, ownerId: String, title: String, description: String, costXp: Int) async throws {
        struct RewardInsert: Encodable {
            let owner_scope: String
            let owner_id: String
            let title: String
            let description: String
            let cost_xp: Int
            let created_by: UUID
        }
        let session = try await client.auth.session
        let row = RewardInsert(
            owner_scope: ownerScope,
            owner_id: ownerId,
            title: title,
            description: description,
            cost_xp: costXp,
            created_by: session.user.id
        )
        try await client.from("rewards").insert(row).execute()
    }

    func fetchRewards(for ownerId: String) async throws -> [RewardItem] {
        let rows: [RewardRow] = try await client
            .from("rewards")
            .select()
            .eq("owner_id", value: ownerId)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map {
            RewardItem(id: $0.id.uuidString, title: $0.title, description: $0.description, costXp: $0.cost_xp)
        }
    }

    func purchaseReward(rewardId: String, squadId: String?) async throws {
        throw NSError(domain: "BitterJuice", code: -1, userInfo: [NSLocalizedDescriptionKey: "Zakup nagrody — do implementacji."])
    }

    // MARK: - Juice Crews (squads)

    func fetchMyJuiceCrews() async throws -> [JuiceCrewItem] {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Sesja wygasła — zaloguj się ponownie."])
        }
        let uid = session.user.id
        let memberships: [SquadMemberLookup] = try await client
            .from("squad_members")
            .select("squad_id")
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value

        let squadIds = memberships.map(\.squad_id)
        guard !squadIds.isEmpty else { return [] }

        let squads: [SquadListRow] = try await client
            .from("squads")
            .select("id,name")
            .in("id", values: squadIds.map { $0 as any PostgrestFilterValue })
            .execute()
            .value

        return squads.map { JuiceCrewItem(id: $0.id.uuidString, name: $0.name) }
    }

    /// Creates a crew, adds you as owner. Returns new crew id.
    func createJuiceCrew(name: String) async throws -> UUID {
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Sesja wygasła — zaloguj się ponownie."])
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "BitterJuice", code: -2, userInfo: [NSLocalizedDescriptionKey: "Podaj nazwę crew."])
        }
        let uid = session.user.id
        let inserted: [SquadIdRow] = try await client
            .from("squads")
            .insert(SquadInsert(name: trimmed, created_by: uid), returning: .representation)
            .select("id")
            .execute()
            .value

        let squadId: UUID
        if let id = inserted.first?.id {
            squadId = id
        } else {
            let fallback: [SquadIdRow] = try await client
                .from("squads")
                .select("id")
                .eq("created_by", value: uid.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            guard let id = fallback.first?.id else {
                throw NSError(
                    domain: "BitterJuice",
                    code: -4,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Could not create or read crew. In Supabase → SQL Editor, run 003_squads.sql then 005_squads_grants.sql (grants for role authenticated)."
                    ]
                )
            }
            squadId = id
        }

        try await client
            .from("squad_members")
            .insert(SquadMemberRow(squad_id: squadId, user_id: uid, role: "owner"))
            .execute()
        return squadId
    }

    /// Join an existing crew by id (friend sent you the UUID).
    func joinJuiceCrew(squadId: String) async throws {
        let trimmed = squadId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let sid = UUID(uuidString: trimmed) else {
            throw NSError(domain: "BitterJuice", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nieprawidłowy UUID crew."])
        }
        let session = try await client.auth.session
        guard !session.isExpired else {
            throw NSError(domain: "BitterJuice", code: -3, userInfo: [NSLocalizedDescriptionKey: "Sesja wygasła — zaloguj się ponownie."])
        }
        try await client
            .from("squad_members")
            .insert(SquadMemberRow(squad_id: sid, user_id: session.user.id, role: "member"))
            .execute()
    }

    private static func payloadToDict(_ object: JSONObject?) -> [String: Any] {
        guard let object else { return [:] }
        return object.mapValues(\.value)
    }

    /// UI uses proud / keepItUp / restABit — DB constraint must match.
    private static func normalizeReaction(_ raw: String) -> String {
        switch raw.lowercased() {
        case "proud": return "proud"
        case "keepitup", "keep_it_up": return "keepItUp"
        case "restabit", "rest_a_bit": return "restABit"
        default: return raw
        }
    }

    /// Use in SwiftUI when showing Supabase/PostgREST failures.
    static func userFacingSupabaseMessage(_ error: Error) -> String {
        let text = error.localizedDescription
        let lower = text.lowercased()
        if lower.contains("schema cache")
            || lower.contains("could not find the table")
            || lower.contains("relation")
            || lower.contains("does not exist")
            || (lower.contains("pgrst") && lower.contains("not found")) {
            return """
            Supabase REST can’t find one or more required tables (or its schema cache is stale).

            Do this on the SAME project as SupabaseConfig.plist:
            1) SQL Editor → run supabase/migrations/009_verify_all_required_tables.sql
               (should return 9 rows).
            2) If rows are missing, run in order:
               001_initial.sql
               002_feed_reactions.sql
               003_squads.sql
               004_activity_logs_reaction_update.sql
               008_all_tables_grants_and_api_reload.sql
            3) If all 9 rows exist but app still fails:
               - Settings → Data API: ensure schema "public" is exposed
               - Settings → General: Pause project, then Resume
               - Wait ~30s and retry.

            Raw error: \(text)
            """
        }
        if lower.contains("permission denied")
            || lower.contains("42501")
            || lower.contains("insufficient privilege") {
            return """
            Supabase rejected this request due to missing table privileges or RLS.

            Run: supabase/migrations/008_all_tables_grants_and_api_reload.sql
            Then retry while signed in (authenticated user).

            Raw error: \(text)
            """
        }
        if lower.contains("infinite recursion"), lower.contains("policy") {
            return """
            Row Level Security on squad_members/squads was recursive (old policies used EXISTS on the same table).

            In Supabase SQL Editor run the full file:
            supabase/migrations/010_fix_squad_rls_recursion.sql

            Then try Create crew again.

            Raw error: \(text)
            """
        }
        return text
    }
}
