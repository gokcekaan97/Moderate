import Foundation

class ModerationService: BaseService, ObservableObject {
    @Published var moderationHistory: [ModerationAction] = []
    @Published var isLoading = false
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func timeoutUser(
        userId: Int,
        channelSlug: String,
        duration: Int,
        reason: String? = nil
    ) async -> Bool {
        return await performModerationAction(
            type: .timeout,
            userId: userId,
            channelSlug: channelSlug,
            duration: duration,
            reason: reason
        )
    }
    
    func banUser(
        userId: Int,
        channelSlug: String,
        reason: String? = nil
    ) async -> Bool {
        return await performModerationAction(
            type: .ban,
            userId: userId,
            channelSlug: channelSlug,
            reason: reason
        )
    }
    
    func unbanUser(
        userId: Int,
        channelSlug: String
    ) async -> Bool {
        return await performModerationAction(
            type: .unban,
            userId: userId,
            channelSlug: channelSlug
        )
    }
    
    func kickUser(
        userId: Int,
        channelSlug: String,
        reason: String? = nil
    ) async -> Bool {
        return await performModerationAction(
            type: .kick,
            userId: userId,
            channelSlug: channelSlug,
            reason: reason
        )
    }
    
    func clearChat(channelSlug: String) async -> Bool {
        guard let token = authService.getAuthToken() else {
            return false
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let _: EmptyResponse = try await request(
                endpoint: "/api/v2/channels/\(channelSlug)/chatroom/clear",
                method: .POST,
                body: nil,
                headers: headers
            )
            
            return true
        } catch {
            print("Failed to clear chat: \(error)")
            return false
        }
    }
    
    func deleteMessage(
        messageId: String,
        channelSlug: String
    ) async -> Bool {
        guard let token = authService.getAuthToken() else {
            return false
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let _: EmptyResponse = try await request(
                endpoint: "/api/v2/channels/\(channelSlug)/messages/\(messageId)",
                method: .DELETE,
                body: nil,
                headers: headers
            )
            
            return true
        } catch {
            print("Failed to delete message: \(error)")
            return false
        }
    }
    
    private func performModerationAction(
        type: ModerationType,
        userId: Int,
        channelSlug: String,
        duration: Int? = nil,
        reason: String? = nil
    ) async -> Bool {
        guard let token = authService.getAuthToken() else {
            return false
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        var requestBody: [String: Any] = [
            "user_id": userId,
            "type": type.rawValue
        ]
        
        if let duration = duration {
            requestBody["duration"] = duration
        }
        
        if let reason = reason {
            requestBody["reason"] = reason
        }
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
            
            let _: ModerationResponse = try await request(
                endpoint: "/api/v2/channels/\(channelSlug)/moderation",
                method: .POST,
                body: bodyData,
                headers: headers
            )
            
            await fetchModerationHistory(channelSlug: channelSlug)
            return true
        } catch {
            print("Failed to perform moderation action: \(error)")
            return false
        }
    }
    
    func fetchModerationHistory(channelSlug: String) async {
        guard let token = authService.getAuthToken() else {
            return
        }
        
        await MainActor.run { isLoading = true }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let response: ModerationHistoryResponse = try await request(
                endpoint: "/api/v2/channels/\(channelSlug)/moderation/history",
                method: .GET,
                body: nil,
                headers: headers
            )
            
            await MainActor.run {
                self.moderationHistory = response.data
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch moderation history: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func getUserModerationInfo(userId: Int, channelSlug: String) async -> UserModerationInfo? {
        guard let token = authService.getAuthToken() else {
            return nil
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let info: UserModerationInfo = try await request(
                endpoint: "/api/v2/channels/\(channelSlug)/users/\(userId)/moderation",
                method: .GET,
                body: nil,
                headers: headers
            )
            
            return info
        } catch {
            print("Failed to fetch user moderation info: \(error)")
            return nil
        }
    }
}

struct ModerationResponse: Codable {
    let success: Bool
    let message: String?
}

struct ModerationHistoryResponse: Codable {
    let data: [ModerationAction]
    let links: PaginationLinks?
    let meta: PaginationMeta?
}

struct UserModerationInfo: Codable {
    let userId: Int
    let isBanned: Bool
    let isTimedOut: Bool
    let timeoutExpiresAt: String?
    let banReason: String?
    let timeoutReason: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isBanned = "is_banned"
        case isTimedOut = "is_timed_out"
        case timeoutExpiresAt = "timeout_expires_at"
        case banReason = "ban_reason"
        case timeoutReason = "timeout_reason"
    }
}

struct EmptyResponse: Codable {
    let success: Bool?
}