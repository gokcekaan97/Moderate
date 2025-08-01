import Foundation

class ChannelService: BaseService, ObservableObject {
    @Published var channels: [Channel] = []
    @Published var selectedChannel: Channel?
    @Published var isLoading = false
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func fetchModeratedChannels() async {
        guard let token = authService.getAuthToken() else {
            return
        }
        
        await MainActor.run { isLoading = true }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        // Try different moderated channels endpoints
        let endpoints = [
            "/api/v2/channels/moderated",
            "/api/v1/channels/moderated", 
            "/api/v2/user/channels",
            "/api/v1/channels/followed"
        ]
        
        for endpoint in endpoints {
            do {
                print("🔍 Trying moderated channels endpoint: \(endpoint)")
                
                let (data, response) = try await URLSession.shared.data(for: createRequest(endpoint: endpoint, method: .GET, body: nil, headers: headers))
                
                guard let httpResponse = response as? HTTPURLResponse else { continue }
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                
                print("📥 Moderated API Response Status: \(httpResponse.statusCode)")
                print("📥 Moderated API Response Body: \(responseString.prefix(200))...")
                
                guard 200...299 ~= httpResponse.statusCode else { continue }
                
                // Check if response is HTML
                if responseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                    print("❌ Moderated API returned HTML instead of JSON")
                    continue
                }
                
                // Try to parse as ChannelsResponse first
                do {
                    let channelsResponse = try JSONDecoder().decode(ChannelsResponse.self, from: data)
                    await MainActor.run {
                        self.channels = channelsResponse.data
                        self.isLoading = false
                    }
                    print("✅ Successfully fetched moderated channels from \(endpoint)")
                    return
                } catch {
                    // Try to parse as direct array
                    do {
                        let directChannels = try JSONDecoder().decode([Channel].self, from: data)
                        await MainActor.run {
                            self.channels = directChannels
                            self.isLoading = false
                        }
                        print("✅ Successfully fetched moderated channels as direct array from \(endpoint)")
                        return
                    } catch {
                        print("❌ Failed to parse channels from \(endpoint): \(error)")
                        continue
                    }
                }
            } catch {
                print("❌ Failed to fetch from \(endpoint): \(error)")
                continue
            }
        }
        
        print("❌ All moderated channels endpoints failed - using empty list")
        await MainActor.run { 
            self.channels = []
            self.isLoading = false 
        }
    }
    
    func fetchChannelDetails(_ slug: String) async -> Channel? {
        guard let token = authService.getAuthToken() else {
            return nil
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let channel: Channel = try await request(
                endpoint: "/api/v2/channels/\(slug)",
                method: .GET,
                body: nil,
                headers: headers
            )
            
            return channel
        } catch {
            print("Failed to fetch channel details: \(error)")
            return nil
        }
    }
    
    func updateChannel(_ slug: String, update: ChannelUpdate) async -> Bool {
        guard let token = authService.getAuthToken() else {
            return false
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        
        do {
            let bodyData = try JSONEncoder().encode(update)
            
            let _: Channel = try await request(
                endpoint: "/api/v2/channels/\(slug)",
                method: .PATCH,
                body: bodyData,
                headers: headers
            )
            
            await fetchChannelDetails(slug)
            return true
        } catch {
            print("Failed to update channel: \(error)")
            return false
        }
    }
    
    func fetchCategories(search: String = "") async -> [Category] {
        let endpoint = search.isEmpty ? 
            "/api/v1/categories" : 
            "/api/v1/categories?search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        do {
            let response: CategoriesResponse = try await request(
                endpoint: endpoint,
                method: .GET,
                body: nil,
                headers: nil
            )
            
            return response.data
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func selectChannel(_ channel: Channel?) {
        selectedChannel = channel
    }
}

struct ChannelsResponse: Codable {
    let data: [Channel]
    let links: PaginationLinks?
    let meta: PaginationMeta?
}

struct CategoriesResponse: Codable {
    let data: [Category]
    let links: PaginationLinks?
    let meta: PaginationMeta?
}

struct PaginationLinks: Codable {
    let first: String?
    let last: String?
    let prev: String?
    let next: String?
}

struct PaginationMeta: Codable {
    let currentPage: Int
    let from: Int?
    let lastPage: Int
    let path: String
    let perPage: Int
    let to: Int?
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case from
        case lastPage = "last_page"
        case path
        case perPage = "per_page"
        case to
        case total
    }
}