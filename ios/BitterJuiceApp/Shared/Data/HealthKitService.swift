import Foundation
import HealthKit

final class HealthKitService {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
    }

    func syncLastNightSleepAsPassiveEvent(squadId: String?) async throws {
        // TODO: Edge Function Supabase lub tabela passive_events + reguły XP
    }
}
