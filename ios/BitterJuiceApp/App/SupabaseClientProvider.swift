import Foundation
import Supabase

enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        guard
            let plistURL = Bundle.main.url(forResource: "SupabaseConfig", withExtension: "plist"),
            let data = NSDictionary(contentsOf: plistURL) as? [String: Any],
            let urlString = data["SUPABASE_URL"] as? String,
            let key = data["SUPABASE_ANON_KEY"] as? String,
            urlString != "REPLACE_ME",
            key != "REPLACE_ME",
            let supabaseURL = URL(string: urlString)
        else {
            fatalError(
                "Uzupełnij ios/BitterJuiceApp/SupabaseConfig.plist (SUPABASE_URL + SUPABASE_ANON_KEY). Instrukcja: docs/SUPABASE-SETUP.md"
            )
        }
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true)
            )
        )
    }()
}
