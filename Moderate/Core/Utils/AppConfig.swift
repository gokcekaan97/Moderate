import Foundation

enum AppConfig {
    enum Keys: String {
        case kickClientID = "KICK_CLIENT_ID"
    }
    
    static var kickClientID: String {
        guard let clientID = ProcessInfo.processInfo.environment[Keys.kickClientID.rawValue],
              !clientID.isEmpty else {
            fatalError("❌ KICK_CLIENT_ID environment variable not set! Please add it to your Xcode scheme.")
        }
        return clientID
    }
    
    // Debug helper
    static func printConfiguration() {
        print("🔧 App Configuration:")
        print("🆔 Kick Client ID: \(kickClientID.prefix(8))...")
    }
}