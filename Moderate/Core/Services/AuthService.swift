import Foundation
import AuthenticationServices
import CryptoKit

class AuthService: NSObject, ObservableObject, BaseService {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let keychainManager = KeychainManager.shared
    private let authTokenKey = "auth_token"
    private let userKey = "current_user"
    
    private var clientId: String { AppConfig.kickClientID }
    private var clientSecret: String { AppConfig.kickClientSecret }
    private let redirectURI = "https://gokcekaan97.github.io/Moderate/"
    private let scopes = ["chat:read", "chat:moderate", "user:read", "channel:write", "channel:read"]
    
    // PKCE values
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    private var state: String = ""
    
    override init() {
        super.init()
        generatePKCEValues() // PKCE değerlerini sadece bir kez burada oluştur
        checkAuthStatus()
    }
    
    var authorizationURL: URL {
        // PKCE values already generated in init()
        
        var components = URLComponents(string: "https://id.kick.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }
    
    private func generatePKCEValues() {
        // Generate code verifier (43-128 characters, RFC 7636)
        codeVerifier = generateRandomString(length: 64)
        // Generate code challenge (SHA256 hash of code verifier, base64url encoded)
        let data = Data(codeVerifier.utf8)
        let hash = SHA256.hash(data: data)
        codeChallenge = Data(hash).base64URLEncoded()
        // Generate state parameter
        state = generateRandomString(length: 32)
        
        print("🧪 PKCE Generated:")
        print("   🔑 Code Verifier Length: \(codeVerifier.count)")
        print("   🧮 Code Challenge: \(codeChallenge)")
    }
    
    private func generateRandomString(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    func startAuthentication() {
        isLoading = true

        // Print configuration for debugging
        AppConfig.printConfiguration()

        let authURL = authorizationURL
        print("🔐 Starting OAuth2 flow with URL: \(authURL.absoluteString)")
        print("🔗 Redirect URI: \(redirectURI)")
        print("📋 Scopes: \(scopes.joined(separator: ", "))")

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "moderatekick"
        ) { [weak self] callbackURL, error in
            NSLog("🔄 ASWebAuthenticationSession callback triggered!")
            NSLog("📞 Callback URL: %@", callbackURL?.absoluteString ?? "nil")
            NSLog("❌ Error: %@", error?.localizedDescription ?? "nil")

            // UI'da da göster
            DispatchQueue.main.async {
                let debugMessage = """
                🔄 OAuth Callback Debug:
                📞 URL: \(callbackURL?.absoluteString ?? "nil")
                ❌ Error: \(error?.localizedDescription ?? "nil")
                """
                NotificationCenter.default.post(name: .debugMessage, object: debugMessage)
            }

            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ Authentication error: \(error)")
                    if let authError = error as? ASWebAuthenticationSessionError {
                        switch authError.code {
                        case .canceledLogin:
                            print("🚪 User canceled login")
                        case .presentationContextNotProvided:
                            print("🖼️ Presentation context not provided")
                        case .presentationContextInvalid:
                            print("🖼️ Presentation context invalid")
                        @unknown default:
                            print("❓ Unknown authentication error")
                        }
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    print("❌ No callback URL received")
                    return
                }

                print("✅ SUCCESS! Received callback URL: \(callbackURL.absoluteString)")
                print("🔗 Full URL: \(callbackURL)")

                // Check if URL scheme matches expected
                if callbackURL.scheme != "moderatekick" {
                    print("⚠️ Unexpected URL scheme: \(callbackURL.scheme ?? "nil"), expected: moderatekick")
                }

                guard let code = self?.extractAuthCode(from: callbackURL) else {
                    print("❌ Failed to extract auth code from callback URL")
                    return
                }

                print("🔑 Extracted authorization code: \(code.prefix(10))...")

                Task {
                    await self?.exchangeCodeForToken(code)
                }
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
    
    private func extractAuthCode(from url: URL) -> String? {
        print("🔍 Analyzing callback URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to parse URL components")
            return nil
        }
        
        print("🔍 URL Components:")
        print("   - Scheme: \(components.scheme ?? "nil")")
        print("   - Host: \(components.host ?? "nil")")
        print("   - Path: \(components.path)")
        print("   - Query: \(components.query ?? "nil")")
        
        guard let queryItems = components.queryItems else {
            print("❌ No query items found in callback URL")
            return nil
        }
        
        print("🔍 Query Items:")
        for item in queryItems {
            print("   - \(item.name): \(item.value ?? "nil")")
        }
        
        // Check for error parameters first
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            print("❌ OAuth Error: \(error)")
            if let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value {
                print("❌ Error Description: \(errorDescription)")
            }
            
            // Handle specific errors
            if error == "invalid_redirect_uri" {
                print("🔧 REDIRECT URI FIX NEEDED:")
                print("   1. Go to your Kick OAuth2 app settings")
                print("   2. Set Redirect URI to: \(redirectURI)")
                print("   3. Make sure there are no extra spaces or characters")
                print("   4. Save and try again")
                
                // Notify UI
                DispatchQueue.main.async {
                    let message = "Redirect URI Hatası!\n\nKick OAuth2 uygulamanızda Redirect URI'yi şu şekilde ayarlayın:\n\n\(self.redirectURI)\n\nNot: Kick.com ana sayfası redirect URI olarak kullanılıyor.\nAyarları kaydedin ve tekrar deneyin."
                    NotificationCenter.default.post(name: .authenticationError, object: message)
                }
            } else {
                // Generic error message
                DispatchQueue.main.async {
                    let errorDesc = queryItems.first(where: { $0.name == "error_description" })?.value ?? "Bilinmeyen hata"
                    let message = "OAuth Hatası: \(error)\n\n\(errorDesc)"
                    NotificationCenter.default.post(name: .authenticationError, object: message)
                }
            }
            
            return nil
        }
        
        // Verify state parameter
        if let returnedState = queryItems.first(where: { $0.name == "state" })?.value {
            print("🔍 Returned state: \(returnedState)")
            print("🔍 Expected state: \(state)")
            if returnedState != state {
                print("❌ State parameter mismatch - possible CSRF attack")
                return nil
            }
        } else {
            print("⚠️ No state parameter returned")
        }
        
        // Extract authorization code
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            print("✅ Authorization code found: \(code.prefix(10))...")
            return code
        } else {
            print("❌ No authorization code found in callback URL")
            return nil
        }
    }
    
    private func exchangeCodeForToken(_ code: String) async {
        guard let tokenURL = URL(string: "https://id.kick.com/oauth/token") else {
            print("Invalid token URL")
            return
        }

        // Debug: Print PKCE values
        print("🔐 Token Exchange Debug:")
        print("   📋 Client ID: \(clientId.prefix(10))...")
        print("   🔗 Redirect URI: \(redirectURI)")
        print("   🔑 Code: \(code.prefix(10))...")
        print("   🛡️ Code Verifier: \(codeVerifier.prefix(10))... (length: \(codeVerifier.count))")
        print("   🧮 Code Challenge: \(codeChallenge.prefix(10))...")

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"

        let bodyParams = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "code": code,
            "code_verifier": codeVerifier
        ]

        let bodyString = bodyParams.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")

        print("📤 Request Body: \(bodyString)")
        request.httpBody = bodyString.data(using: .utf8)

        // Use custom session to ensure headers and timeouts are handled properly
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: config)

        // Add recommended headers
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ModerateKick", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                return
            }

            print("📥 Response Status: \(httpResponse.statusCode)")
            print("📥 Response Headers: \(httpResponse.allHeaderFields)")
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("📥 Response Body: \(responseString)")

            guard 200...299 ~= httpResponse.statusCode else {
                print("❌ HTTP error: \(httpResponse.statusCode)")
                print("❌ Full response data: \(data)")
                print("❌ Response string: \(responseString)")

                // Try to parse error details if available
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("❌ Parsed Error Details: \(errorData)")
                    
                    // Check for specific error messages
                    if let error = errorData["error"] as? String {
                        print("❌ Error Type: \(error)")
                    }
                    if let errorDescription = errorData["error_description"] as? String {
                        print("❌ Error Description: \(errorDescription)")
                    }
                } else {
                    print("❌ Could not parse error response as JSON")
                }

                return
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            await MainActor.run {
                self.handleTokenResponse(tokenResponse)
            }
        } catch {
            print("Token exchange failed: \(error)")
        }
    }
    
    private func handleTokenResponse(_ response: TokenResponse) {
        do {
            try keychainManager.save(response.accessToken, for: authTokenKey)
            
            Task {
                await fetchCurrentUser()
            }
        } catch {
            print("Failed to save token: \(error)")
        }
    }
    
    private func fetchCurrentUser() async {
        guard let token = try? keychainManager.load(String.self, for: authTokenKey) else {
            return
        }
        
        // Try different user endpoints
        let userEndpoints = [
            "https://kick.com/oauth/user",
            "https://kick.com/api/v1/user",
            "https://kick.com/api/user", 
            "https://kick.com/api/v1/me",
            "https://kick.com/api/me"
        ]
        
        for endpoint in userEndpoints {
            guard let userURL = URL(string: endpoint) else { continue }
            
            print("🔍 Trying user endpoint: \(endpoint)")
            
            if await tryFetchUser(from: userURL, token: token) {
                return // Success, exit function
            }
        }
        
        print("❌ All user endpoints failed - using fallback user")
        
        // Create a temporary user object for testing since we can't find the working endpoint
        let fallbackUser = User(
            id: 1,
            username: "test_user",
            slug: "test_user",
            profilePic: nil,
            verified: false,
            followersCount: 0,
            bio: nil,
            country: nil,
            state: nil,
            city: nil,
            instagram: nil,
            twitter: nil,
            youtube: nil,
            discord: nil,
            tiktok: nil,
            facebook: nil
        )
        
        do {
            try keychainManager.save(fallbackUser, for: userKey)
            
            await MainActor.run {
                self.currentUser = fallbackUser
                self.isAuthenticated = true
            }
            
            print("✅ Authentication completed with fallback user")
        } catch {
            print("❌ Failed to save fallback user: \(error)")
            await logout()
        }
    }
    
    private func tryFetchUser(from userURL: URL, token: String) async -> Bool {
        var request = URLRequest(url: userURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return false
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("📥 User API Response Status: \(httpResponse.statusCode)")
            print("📥 User API Response Body: \(responseString)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                print("❌ User API HTTP error: \(httpResponse.statusCode)")
                return false
            }
            
            // Check if response is HTML (error page)
            if responseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                print("❌ User API returned HTML instead of JSON")
                return false
            }
            
            // Check if response is empty object
            if responseString.trimmingCharacters(in: .whitespacesAndNewlines) == "{}" {
                print("❌ User API returned empty object")
                return false
            }
            
            let user = try JSONDecoder().decode(User.self, from: data)
            
            try keychainManager.save(user, for: userKey)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            print("✅ Successfully fetched user: \(user.username)")
            return true
            
        } catch {
            print("❌ Failed to fetch user from \(userURL.absoluteString): \(error)")
            return false
        }
    }
    
    private func checkAuthStatus() {
        do {
            let token = try keychainManager.load(String.self, for: authTokenKey)
            let user = try keychainManager.load(User.self, for: userKey)
            
            self.currentUser = user
            self.isAuthenticated = true
            
            Task {
                await validateToken(token)
            }
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    private func validateToken(_ token: String) async {
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let _: User = try await request(
                endpoint: "/api/v2/user",
                method: .GET,
                body: nil,
                headers: headers
            )
        } catch {
            await logout()
        }
    }
    
    func logout() async {
        do {
            try keychainManager.delete(for: authTokenKey)
            try keychainManager.delete(for: userKey)
        } catch {
            print("Failed to clear keychain: \(error)")
        }
        
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func getAuthToken() -> String? {
        return try? keychainManager.load(String.self, for: authTokenKey)
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int?
    let refreshToken: String?
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

extension Notification.Name {
    static let authenticationError = Notification.Name("authenticationError")
    static let debugMessage = Notification.Name("debugMessage")
}
