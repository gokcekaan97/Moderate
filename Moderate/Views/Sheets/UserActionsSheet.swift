import SwiftUI

struct UserActionsSheet: View {
    let user: MessageSender
    let channelSlug: String
    @Binding var isPresented: Bool
    
    @EnvironmentObject var moderationService: ModerationService
    @State private var userInfo: UserModerationInfo?
    @State private var isLoading = false
    @State private var showingTimeoutSheet = false
    @State private var showingBanSheet = false
    @State private var showingKickSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                UserInfoHeader(user: user)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                } else {
                    UserStatusView(userInfo: userInfo)
                    
                    ModerationActionsView(
                        user: user,
                        userInfo: userInfo,
                        showingTimeoutSheet: $showingTimeoutSheet,
                        showingBanSheet: $showingBanSheet,
                        showingKickSheet: $showingKickSheet
                    )
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Kullanıcı İşlemleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        isPresented = false
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            loadUserInfo()
        }
        .sheet(isPresented: $showingTimeoutSheet) {
            TimeoutSheet(
                userId: user.id,
                username: user.username,
                channelSlug: channelSlug,
                isPresented: $showingTimeoutSheet,
                onComplete: {
                    loadUserInfo()
                }
            )
        }
        .sheet(isPresented: $showingBanSheet) {
            BanSheet(
                userId: user.id,
                username: user.username,
                channelSlug: channelSlug,
                isPresented: $showingBanSheet,
                onComplete: {
                    loadUserInfo()
                }
            )
        }
        .sheet(isPresented: $showingKickSheet) {
            KickSheet(
                userId: user.id,
                username: user.username,
                channelSlug: channelSlug,
                isPresented: $showingKickSheet,
                onComplete: {
                    loadUserInfo()
                }
            )
        }
    }
    
    private func loadUserInfo() {
        isLoading = true
        Task {
            let info = await moderationService.getUserModerationInfo(
                userId: user.id,
                channelSlug: channelSlug
            )
            
            await MainActor.run {
                self.userInfo = info
                self.isLoading = false
            }
        }
    }
}

struct UserInfoHeader: View {
    let user: MessageSender
    
    var body: some View {
        VStack(spacing: 15) {
            AsyncImage(url: URL(string: "https://kick.com/img/user-avatar.png")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            VStack(spacing: 5) {
                Text(user.username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("ID: \(user.id)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let badges = user.identity.badges, !badges.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(badges.indices, id: \.self) { index in
                            let badge = badges[index]
                            BadgeView(badge: badge)
                        }
                    }
                }
            }
        }
    }
}

struct UserStatusView: View {
    let userInfo: UserModerationInfo?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Kullanıcı Durumu")
                .font(.headline)
                .foregroundColor(.white)
            
            if let info = userInfo {
                VStack(spacing: 8) {
                    StatusRow(
                        title: "Yasaklı",
                        status: info.isBanned,
                        icon: "hand.raised"
                    )
                    
                    StatusRow(
                        title: "Susturulmuş",
                        status: info.isTimedOut,
                        icon: "clock"
                    )
                    
                    if info.isBanned, let reason = info.banReason {
                        HStack {
                            Text("Yasak Sebebi:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if info.isTimedOut, let expiresAt = info.timeoutExpiresAt {
                        HStack {
                            Text("Susturma Bitiş:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(formatDate(expiresAt))
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("Bilgi yüklenemedi")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            return date.formatted(.dateTime.hour().minute().weekday().month().day())
        }
        return dateString
    }
}

struct StatusRow: View {
    let title: String
    let status: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status ? .red : .green)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(status ? "Evet" : "Hayır")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(status ? .red : .green)
        }
    }
}

struct ModerationActionsView: View {
    let user: MessageSender
    let userInfo: UserModerationInfo?
    @Binding var showingTimeoutSheet: Bool
    @Binding var showingBanSheet: Bool
    @Binding var showingKickSheet: Bool
    
    @EnvironmentObject var moderationService: ModerationService
    @State private var isPerformingAction = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Moderasyon İşlemleri")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ModerationButton(
                    title: "Sustur",
                    icon: "clock",
                    color: .orange,
                    isEnabled: !(userInfo?.isTimedOut ?? false) && !isPerformingAction
                ) {
                    showingTimeoutSheet = true
                }
                
                if userInfo?.isBanned == true {
                    ModerationButton(
                        title: "Yasağı Kaldır",
                        icon: "hand.raised.slash",
                        color: .green,
                        isEnabled: !isPerformingAction
                    ) {
                        performUnban()
                    }
                } else {
                    ModerationButton(
                        title: "Yasakla",
                        icon: "hand.raised",
                        color: .red,
                        isEnabled: !isPerformingAction
                    ) {
                        showingBanSheet = true
                    }
                }
                
                ModerationButton(
                    title: "Atılma",
                    icon: "person.crop.circle.badge.minus",
                    color: .purple,
                    isEnabled: !isPerformingAction
                ) {
                    showingKickSheet = true
                }
            }
        }
    }
    
    private func performUnban() {
        isPerformingAction = true
        Task {
            // Implementation would go here
            await MainActor.run {
                isPerformingAction = false
            }
        }
    }
}

struct ModerationButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                
                Text(title)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding()
            .background(isEnabled ? color : Color.gray)
            .foregroundColor(isEnabled ? .white : .gray)
            .cornerRadius(10)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    UserActionsSheet(
        user: MessageSender(
            id: 123,
            username: "testuser",
            slug: "testuser",
            identity: MessageSender.Identity(color: "#FFFFFF", badges: nil)
        ),
        channelSlug: "test-channel",
        isPresented: .constant(true)
    )
    .environmentObject(ModerationService(authService: AuthService()))
    .preferredColorScheme(.dark)
}