import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var channelService: ChannelService
    @State private var selectedUser: MessageSender?
    @State private var showingUserActions = false
    
    var body: some View {
        VStack(spacing: 0) {
            if chatService.messages.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Henüz mesaj yok")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Chat mesajları burada görünecek")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(chatService.messages) { message in
                                MessageView(message: message) { sender in
                                    selectedUser = sender
                                    showingUserActions = true
                                }
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: chatService.messages.count) { _ in
                        if let lastMessage = chatService.messages.last {
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            ChatToolbar()
        }
        .background(Color.black)
        .sheet(isPresented: $showingUserActions) {
            if let user = selectedUser,
               let channel = channelService.selectedChannel {
                UserActionsSheet(
                    user: user,
                    channelSlug: channel.slug,
                    isPresented: $showingUserActions
                )
            }
        }
    }
}

struct MessageView: View {
    let message: ChatMessage
    let onUserTap: (MessageSender) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                onUserTap(message.sender)
            }) {
                AsyncImage(url: URL(string: "https://kick.com/img/user-avatar.png")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Button(action: {
                        onUserTap(message.sender)
                    }) {
                        Text(message.sender.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: message.sender.identity.color ?? "#FFFFFF"))
                    }
                    
                    if let badges = message.sender.identity.badges {
                        ForEach(badges.indices, id: \.self) { index in
                            let badge = badges[index]
                            BadgeView(badge: badge)
                        }
                    }
                    
                    Spacer()
                    
                    Text(message.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct BadgeView: View {
    let badge: MessageSender.Badge
    
    var body: some View {
        Text(badge.text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var badgeColor: Color {
        switch badge.type.lowercased() {
        case "moderator":
            return .green
        case "vip":
            return .purple
        case "subscriber":
            return .blue
        default:
            return .gray
        }
    }
}

struct ChatToolbar: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var moderationService: ModerationService
    @EnvironmentObject var channelService: ChannelService
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                chatService.clearMessages()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                if let channel = channelService.selectedChannel {
                    Task {
                        await moderationService.clearChat(channelSlug: channel.slug)
                    }
                }
            }) {
                Image(systemName: "clear")
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Text("\(chatService.messages.count) mesaj")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                if let channel = channelService.selectedChannel {
                    chatService.connectToChat(channelId: channel.chatroom?.chatroomId ?? channel.id)
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatService(authService: AuthService()))
        .environmentObject(ChannelService(authService: AuthService()))
        .environmentObject(ModerationService(authService: AuthService()))
        .preferredColorScheme(.dark)
}