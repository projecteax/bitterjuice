import Foundation

/// Upload na R2 — wcześniej przez Firebase Callable; z Supabase możesz dodać Edge Function lub podpisany URL.
final class R2UploadService {
    func requestUploadToken(mediaType: String, mimeType: String) async throws -> UploadToken {
        throw NSError(
            domain: "R2UploadService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "R2 upload: skonfiguruj Edge Function lub backend z podpisanym URL."]
        )
    }

    func upload(data: Data, mimeType: String, token: UploadToken) async throws {
        throw NSError(domain: "R2UploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}

struct UploadToken {
    let assetId: String
    let key: String
    let uploadUrl: URL
    let publicUrl: URL
}
