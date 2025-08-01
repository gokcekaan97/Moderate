import Foundation

enum AppConfig {
    enum Keys: String {
        case kickClientID = "KICK_CLIENT_ID"
        case kickClientSecret = "KICK_CLIENT_SECRET"
    }
    
    static var kickClientID: String {
        guard let clientID = ProcessInfo.processInfo.environment[Keys.kickClientID.rawValue],
              !clientID.isEmpty else {
            fatalError("❌ KICK_CLIENT_ID environment variable not set! Please add it to your Xcode scheme.")
        }
        return clientID
    }
    
    static var kickClientSecret: String {
        guard let clientSecret = ProcessInfo.processInfo.environment[Keys.kickClientSecret.rawValue],
              !clientSecret.isEmpty else {
            fatalError("❌ KICK_CLIENT_SECRET environment variable not set! Please add it to your Xcode scheme.")
        }
        return clientSecret
    }
    
    // Debug helper
    static func printConfiguration() {
        print("🔧 App Configuration:")
        print("🆔 Kick Client ID: \(kickClientID.prefix(8))...")
        print("🔐 Kick Client Secret: \(kickClientSecret.prefix(8))...")
    }
}