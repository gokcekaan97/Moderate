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
        
        do {
            let response: ChannelsResponse = try await request(
                endpoint: "/api/v2/channels/moderated",
                method: .GET,
                body: nil,
                headers: headers
            )
            
            await MainActor.run {
                self.channels = response.data
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch moderated channels: \(error)")
            await MainActor.run { isLoading = false }
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