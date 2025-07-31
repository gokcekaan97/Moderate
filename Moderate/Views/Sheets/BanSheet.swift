import SwiftUI

struct BanSheet: View {
    let userId: Int
    let username: String
    let channelSlug: String
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @EnvironmentObject var moderationService: ModerationService
    @State private var reason = ""
    @State private var isPerformingAction = false
    @State private var confirmBan = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Kullanıcıyı Yasakla")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("@\(username) kullanıcısını kalıcı olarak yasaklayacaksınız.")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Text("Bu işlem geri alınabilir.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sebep (İsteğe bağlı)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Yasaklama sebebini yazın...", text: $reason, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .colorScheme(.dark)
                        .lineLimit(3...6)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button(action: {
                            confirmBan.toggle()
                        }) {
                            Image(systemName: confirmBan ? "checkmark.square.fill" : "square")
                                .foregroundColor(confirmBan ? .red : .gray)
                        }
                        
                        Text("Bu işlemi yapmak istediğimi onaylıyorum")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: performBan) {
                        HStack {
                            if isPerformingAction {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "hand.raised")
                            }
                            
                            Text(isPerformingAction ? "Yasaklanıyor..." : "Yasakla")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(confirmBan && !isPerformingAction ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!confirmBan || isPerformingAction)
                    
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
            .navigationTitle("Yasakla")
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
    
    private func performBan() {
        guard confirmBan else { return }
        
        isPerformingAction = true
        
        Task {
            let success = await moderationService.banUser(
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
    BanSheet(
        userId: 123,
        username: "testuser",
        channelSlug: "test-channel",
        isPresented: .constant(true),
        onComplete: {}
    )
    .environmentObject(ModerationService(authService: AuthService()))
    .preferredColorScheme(.dark)
}