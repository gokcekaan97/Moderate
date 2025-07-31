import SwiftUI

struct KickSheet: View {
    let userId: Int
    let username: String
    let channelSlug: String
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @EnvironmentObject var moderationService: ModerationService
    @State private var reason = ""
    @State private var isPerformingAction = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Kullanıcıyı At")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("@\(username) kullanıcısını kanaldan atacaksınız.")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Text("Kullanıcı tekrar kanala girebilir.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sebep (İsteğe bağlı)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Atılma sebebini yazın...", text: $reason, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .colorScheme(.dark)
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: performKick) {
                        HStack {
                            if isPerformingAction {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.crop.circle.badge.minus")
                            }
                            
                            Text(isPerformingAction ? "Atılıyor..." : "At")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isPerformingAction)
                    
                    Button("İptal") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Kullanıcı At")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private func performKick() {
        isPerformingAction = true
        
        Task {
            let success = await moderationService.kickUser(
                userId: userId,
                channelSlug: channelSlug,
                reason: reason.isEmpty ? nil : reason
            )
            
            await MainActor.run {
                isPerformingAction = false
                
                if success {
                    onComplete()
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    KickSheet(
        userId: 123,
        username: "testuser",
        channelSlug: "test-channel",
        isPresented: .constant(true),
        onComplete: {}
    )
    .environmentObject(ModerationService(authService: AuthService()))
    .preferredColorScheme(.dark)
}