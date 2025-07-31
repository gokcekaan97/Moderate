import Foundation

struct Channel: Codable, Identifiable, Equatable {
    let id: Int
    let userId: Int
    let slug: String
    let playbackUrl: String?
    let vods: Bool
    let followersCount: Int
    let user: User
    let isLive: Bool
    let category: Category?
    let tags: [String]?
    let viewersCount: Int?
    let chatroom: Chatroom?
    let recentMessage: String?
    let thumbnail: Thumbnail?
    let duration: Int?
    let language: String?
    let isMature: Bool
    let viewerCountVisible: Bool
    let chatModeOld: String?
    let chatMode: String?
    let slowMode: Bool
    let subscriberMode: Bool
    let followersMode: Bool
    let emotesMode: Bool
    let message: String?
    let offlinebannerImage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case slug
        case playbackUrl = "playback_url"
        case vods
        case followersCount = "followers_count"
        case user
        case isLive = "is_live"
        case category
        case tags
        case viewersCount = "viewers_count"
        case chatroom
        case recentMessage = "recent_message"
        case thumbnail
        case duration
        case language
        case isMature = "is_mature"
        case viewerCountVisible = "viewer_count_visible"
        case chatModeOld = "chat_mode_old"
        case chatMode = "chat_mode"
        case slowMode = "slow_mode"
        case subscriberMode = "subscriber_mode"
        case followersMode = "followers_mode"
        case emotesMode = "emotes_mode"
        case message
        case offlinebannerImage = "offlinebanner_image"
    }
}

struct Category: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let slug: String
    let tags: [String]?
    let description: String?
    let deletedAt: String?
    let viewers: Int?
    let category: ParentCategory?
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, tags, description, viewers, category
        case deletedAt = "deleted_at"
    }
}

struct ParentCategory: Codable, Equatable {
    let id: Int
    let name: String
    let slug: String
    let icon: String?
}

struct Chatroom: Codable, Identifiable, Equatable {
    let id: Int
    let chatroomId: Int
    let channelId: Int
    let createdAt: String
    let updatedAt: String
    let chatModeOld: String
    let chatMode: String
    let slowMode: Bool
    let chatroomClearAt: String?
    let followersMode: Bool
    let subscribersMode: Bool
    let emotesMode: Bool
    let messageInterval: Int
    let followingMinDuration: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatroomId = "chatroom_id"
        case channelId = "channel_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case chatModeOld = "chat_mode_old"
        case chatMode = "chat_mode"
        case slowMode = "slow_mode"
        case chatroomClearAt = "chatroom_clear_at"
        case followersMode = "followers_mode"
        case subscribersMode = "subscribers_mode"
        case emotesMode = "emotes_mode"
        case messageInterval = "message_interval"
        case followingMinDuration = "following_min_duration"
    }
}

struct Thumbnail: Codable, Equatable {
    let responsive: String?
    let url: String?
}

struct ChannelUpdate: Codable {
    let title: String?
    let categoryId: Int?
    let language: String?
    let isMature: Bool?
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case categoryId = "category_id"
        case language
        case isMature = "is_mature"
        case tags
    }
}