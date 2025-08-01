import Foundation

extension Data {
    func base64URLEncoded() -> String {
        return self.base64EncodedString(options: [])
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
