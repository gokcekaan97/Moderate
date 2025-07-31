import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let chatroomId: Int
    let content: String
    let type: String
    let createdAt: String
    let sender: MessageSender
    let metadata: MessageMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id, content, type, sender, metadata
        case chatroomId = "chatroom_id"
        case createdAt = "created_at"
    }
    
    var timestamp: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
}

struct MessageSender: Codable, Equatable {
    let id: Int
    let username: String
    let slug: String
    let identity: Identity
    
    struct Identity: Codable, Equatable {
        let color: String?
        let badges: [Badge]?
    }
    
    struct Badge: Codable, Equatable {
        let type: String
        let text: String
        let count: Int?
        let active: Bool?
    }
}

struct MessageMetadata: Codable, Equatable {
    let originalSender: MessageSender?
    let originalMessage: OriginalMessage?
    
    enum CodingKeys: String, CodingKey {
        case originalSender = "original_sender"
        case originalMessage = "original_message"
    }
    
    struct OriginalMessage: Codable, Equatable {
        let id: String
        let content: String
    }
}

struct ModerationAction: Codable, Identifiable {
    let id: String
    let type: ModerationType
    let targetUserId: Int
    let targetUsername: String
    let moderatorId: Int
    let moderatorUsername: String
    let reason: String?
    let duration: Int?
    let createdAt: Date
    let chatroomId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, type, reason, duration
        case targetUserId = "target_user_id"
        case targetUsername = "target_username"
        case moderatorId = "moderator_id"
        case moderatorUsername = "moderator_username"
        case createdAt = "created_at"
        case chatroomId = "chatroom_id"
    }
}

enum ModerationType: String, Codable, CaseIterable {
    case timeout = "timeout"
    case ban = "ban"
    case unban = "unban"
    case kick = "kick"
    case chatClear = "chat_clear"
    case messageDelete = "message_delete"
    
    var displayName: String {
        switch self {
        case .timeout: return "Timeout"
        case .ban: return "Ban"
        case .unban: return "Unban"
        case .kick: return "Kick"
        case .chatClear: return "Chat Clear"
        case .messageDelete: return "Delete Message"
        }
    }
}