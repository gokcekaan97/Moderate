import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var channelService: ChannelService
    @EnvironmentObject var chatService: ChatService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
                .tag(0)
            
            ModerationView()
                .tabItem {
                    Image(systemName: "shield")
                    Text("Moderasyon")
                }
                .tag(1)
            
            ChannelInfoView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("Kanal Bilgileri")
                }
                .tag(2)
        }
        .accentColor(.green)
        .onAppear {
            if let channel = channelService.selectedChannel {
                chatService.connectToChat(channelId: channel.chatroom?.chatroomId ?? channel.id)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Kanallar") {
                    channelService.selectChannel(nil)
                    chatService.disconnect()
                }
                .foregroundColor(.green)
            }
            
            ToolbarItem(placement: .principal) {
                if let channel = channelService.selectedChannel {
                    VStack(spacing: 2) {
                        Text(channel.user.username)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(connectionStatusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(connectionStatusText)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
    
    private var connectionStatusColor: Color {
        switch chatService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .error:
            return .red
        }
    }
    
    private var connectionStatusText: String {
        switch chatService.connectionStatus {
        case .connected:
            return "Bağlı"
        case .connecting:
            return "Bağlanıyor..."
        case .disconnected:
            return "Bağlantı kesildi"
        case .error:
            return "Hata"
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ChannelService(authService: AuthService()))
        .environmentObject(ChatService(authService: AuthService()))
        .environmentObject(ModerationService(authService: AuthService()))
        .preferredColorScheme(.dark)
}