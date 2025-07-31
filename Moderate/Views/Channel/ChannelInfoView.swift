import SwiftUI

struct ChannelInfoView: View {
    @EnvironmentObject var channelService: ChannelService
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            if let channel = channelService.selectedChannel {
                VStack(spacing: 20) {
                    ChannelHeaderView(channel: channel)
                    
                    ChannelStatsView(channel: channel)
                    
                    ChannelSettingsView(channel: channel)
                    
                    Button("Kanal Bilgilerini Düzenle") {
                        showingEditSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showingEditSheet) {
            if let channel = channelService.selectedChannel {
                ChannelEditSheet(
                    channel: channel,
                    isPresented: $showingEditSheet
                )
            }
        }
    }
}

struct ChannelHeaderView: View {
    let channel: Channel
    
    var body: some View {
        VStack(spacing: 15) {
            AsyncImage(url: URL(string: channel.user.profilePic ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(spacing: 5) {
                HStack {
                    Text(channel.user.username)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if channel.isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("CANLI")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if let category = channel.category {
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                if let message = channel.message, !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct ChannelStatsView: View {
    let channel: Channel
    
    var body: some View {
        HStack(spacing: 30) {
            StatView(
                title: "Takipçiler",
                value: "\(channel.followersCount)",
                icon: "person.2"
            )
            
            if let viewersCount = channel.viewersCount {
                StatView(
                    title: "İzleyiciler",
                    value: "\(viewersCount)",
                    icon: "eye"
                )
            }
            
            if channel.isLive, let duration = channel.duration {
                StatView(
                    title: "Süre",
                    value: formatDuration(duration),
                    icon: "clock"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ChannelSettingsView: View {
    let channel: Channel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Kanal Ayarları")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                SettingRow(
                    title: "Yavaş Mod",
                    value: channel.slowMode ? "Açık" : "Kapalı",
                    icon: "tortoise",
                    isEnabled: channel.slowMode
                )
                
                SettingRow(
                    title: "Abone Modu",
                    value: channel.subscriberMode ? "Açık" : "Kapalı",
                    icon: "star",
                    isEnabled: channel.subscriberMode
                )
                
                SettingRow(
                    title: "Takipçi Modu",
                    value: channel.followersMode ? "Açık" : "Kapalı",
                    icon: "person.2",
                    isEnabled: channel.followersMode
                )
                
                SettingRow(
                    title: "Emote Modu",
                    value: channel.emotesMode ? "Açık" : "Kapalı",
                    icon: "face.smiling",
                    isEnabled: channel.emotesMode
                )
                
                SettingRow(
                    title: "Yetişkin İçerik",
                    value: channel.isMature ? "Evet" : "Hayır",
                    icon: "exclamationmark.triangle",
                    isEnabled: channel.isMature
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    let icon: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(isEnabled ? .green : .gray)
        }
    }
}

#Preview {
    ChannelInfoView()
        .environmentObject(ChannelService(authService: AuthService()))
        .preferredColorScheme(.dark)
}