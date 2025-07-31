import SwiftUI

struct ModerationView: View {
    @EnvironmentObject var moderationService: ModerationService
    @EnvironmentObject var channelService: ChannelService
    
    var body: some View {
        VStack(spacing: 0) {
            if moderationService.isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.2)
                    
                    Text("Moderasyon geçmişi yükleniyor...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if moderationService.moderationHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Moderasyon Geçmişi Yok")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Henüz herhangi bir moderasyon eylemi gerçekleştirilmemiş")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(moderationService.moderationHistory) { action in
                            ModerationActionRow(action: action)
                        }
                    }
                    .padding()
                }
            }
            
            ModerationToolbar()
        }
        .background(Color.black)
        .onAppear {
            if let channel = channelService.selectedChannel {
                Task {
                    await moderationService.fetchModerationHistory(channelSlug: channel.slug)
                }
            }
        }
    }
}

struct ModerationActionRow: View {
    let action: ModerationAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForActionType(action.type))
                    .foregroundColor(colorForActionType(action.type))
                    .frame(width: 20)
                
                Text(action.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(action.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Hedef:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(action.targetUsername)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Moderatör:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(action.moderatorUsername)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                if let duration = action.duration {
                    HStack {
                        Text("Süre:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(duration) saniye")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let reason = action.reason, !reason.isEmpty {
                    HStack {
                        Text("Sebep:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func iconForActionType(_ type: ModerationType) -> String {
        switch type {
        case .timeout:
            return "clock"
        case .ban:
            return "hand.raised"
        case .unban:
            return "hand.raised.slash"
        case .kick:
            return "person.crop.circle.badge.minus"
        case .chatClear:
            return "clear"
        case .messageDelete:
            return "trash"
        }
    }
    
    private func colorForActionType(_ type: ModerationType) -> Color {
        switch type {
        case .timeout:
            return .orange
        case .ban:
            return .red
        case .unban:
            return .green
        case .kick:
            return .purple
        case .chatClear:
            return .blue
        case .messageDelete:
            return .gray
        }
    }
}

struct ModerationToolbar: View {
    @EnvironmentObject var moderationService: ModerationService
    @EnvironmentObject var channelService: ChannelService
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                if let channel = channelService.selectedChannel {
                    Task {
                        await moderationService.clearChat(channelSlug: channel.slug)
                    }
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "clear")
                        .foregroundColor(.blue)
                    Text("Chat Temizle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Text("\(moderationService.moderationHistory.count) eylem")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                if let channel = channelService.selectedChannel {
                    Task {
                        await moderationService.fetchModerationHistory(channelSlug: channel.slug)
                    }
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

#Preview {
    ModerationView()
        .environmentObject(ModerationService(authService: AuthService()))
        .environmentObject(ChannelService(authService: AuthService()))
        .preferredColorScheme(.dark)
}