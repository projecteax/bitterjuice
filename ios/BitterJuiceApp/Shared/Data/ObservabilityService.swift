import Foundation

/// Placeholder — możesz dodać Sentry / Telemetry później.
final class ObservabilityService {
    static let shared = ObservabilityService()

    private init() {}

    func track(_ name: String, params: [String: Any] = [:]) {}

    func record(error: Error, context: String) {
        #if DEBUG
        print("[Observability]", context, error.localizedDescription)
        #endif
    }
}
