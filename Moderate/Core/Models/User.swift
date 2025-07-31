import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let username: String
    let slug: String
    let profilePic: String?
    let verified: Bool?
    let followersCount: Int?
    let bio: String?
    let country: String?
    let state: String?
    let city: String?
    let instagram: String?
    let twitter: String?
    let youtube: String?
    let discord: String?
    let tiktok: String?
    let facebook: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, slug, verified, bio, country, state, city
        case profilePic = "profile_pic"
        case followersCount = "followers_count"
        case instagram = "instagram"
        case twitter = "twitter"
        case youtube = "youtube"
        case discord = "discord"
        case tiktok = "tiktok"
        case facebook = "facebook"
    }
}

struct AuthenticatedUser: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}