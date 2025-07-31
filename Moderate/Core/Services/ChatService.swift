import Foundation
import Network

class ChatService: NSObject, ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isLoading = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let authService: AuthService
    private var currentChannelId: Int?
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error
    }
    
    init(authService: AuthService) {
        self.authService = authService
        super.init()
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func connectToChat(channelId: Int) {
        currentChannelId = channelId
        disconnect()
        
        guard let token = authService.getAuthToken() else {
            print("No auth token available")
            return
        }
        
        let wsURL = URL(string: "wss://ws-us2.pusher.com/app/32cbd69e4b950bf97679?protocol=7&client=js&version=7.4.0&flash=false")!
        
        webSocketTask = urlSession?.webSocketTask(with: wsURL)
        webSocketTask?.delegate = self
        
        DispatchQueue.main.async {
            self.connectionStatus = .connecting
        }
        
        webSocketTask?.resume()
        listenForMessages()
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await subscribeToChannel(channelId: channelId, token: token)
        }
    }
    
    private func subscribeToChannel(channelId: Int, token: String) async {
        let subscribeMessage = PusherMessage(
            event: "pusher:subscribe",
            data: PusherSubscribeData(
                auth: token,
                channel: "chatrooms.\(channelId).v2"
            )
        )
        
        do {
            let messageData = try JSONEncoder().encode(subscribeMessage)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            let message = URLSessionWebSocketTask.Message.string(messageString)
            
            try await webSocketTask?.send(message)
            print("Subscribed to channel: \(channelId)")
        } catch {
            print("Failed to subscribe to channel: \(error)")
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                self?.listenForMessages()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.connectionStatus = .error
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleStringMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleStringMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func handleStringMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let pusherMessage = try JSONDecoder().decode(PusherIncomingMessage.self, from: data)
            
            switch pusherMessage.event {
            case "pusher:connection_established":
                DispatchQueue.main.async {
                    self.connectionStatus = .connected
                }
                
            case "App\\Events\\ChatMessageEvent":
                if let messageData = pusherMessage.data?.data(using: .utf8) {
                    let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: messageData)
                    DispatchQueue.main.async {
                        self.messages.append(chatMessage)
                        self.messages = Array(self.messages.suffix(200))
                    }
                }
                
            case "pusher_internal:subscription_succeeded":
                print("Successfully subscribed to channel")
                
            default:
                print("Unhandled event: \(pusherMessage.event)")
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
        }
    }
    
    func clearMessages() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
    
    deinit {
        disconnect()
    }
}

extension ChatService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        DispatchQueue.main.async {
            self.connectionStatus = .connected
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
        }
    }
}

extension ChatService: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("URLSession became invalid: \(error?.localizedDescription ?? "Unknown error")")
    }
}

struct PusherMessage: Codable {
    let event: String
    let data: PusherSubscribeData
}

struct PusherSubscribeData: Codable {
    let auth: String
    let channel: String
}

struct PusherIncomingMessage: Codable {
    let event: String
    let data: String?
    let channel: String?
}