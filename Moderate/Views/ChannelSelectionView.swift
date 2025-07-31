import SwiftUI

struct ChannelSelectionView: View {
    @EnvironmentObject var channelService: ChannelService
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Kanal Seçimi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Yönetmek istediğiniz kanalı seçin")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                if channelService.isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(1.2)
                        
                        Text("Kanallar yükleniyor...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if channelService.channels.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Moderatör Olduğunuz Kanal Bulunamadı")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Henüz hiçbir kanalda moderatör olarak yetkilendirilmemişsiniz.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(channelService.channels) { channel in
                                ChannelRowView(channel: channel) {
                                    channelService.selectChannel(channel)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Çıkış") {
                        Task {
                            await authService.logout()
                        }
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Yenile") {
                        Task {
                            await channelService.fetchModeratedChannels()
                        }
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            Task {
                await channelService.fetchModeratedChannels()
            }
        }
        .background(Color.black)
    }
}

struct ChannelRowView: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                AsyncImage(url: URL(string: channel.user.profilePic ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(channel.user.username)
                            .font(.headline)
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
                        
                        Spacer()
                    }
                    
                    if let category = channel.category {
                        Text(category.name)
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "person.2")
                        Text("\(channel.followersCount) takipçi")
                        
                        if let viewersCount = channel.viewersCount {
                            Image(systemName: "eye")
                            Text("\(viewersCount) izleyici")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ChannelSelectionView()
        .environmentObject(ChannelService(authService: AuthService()))
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
}