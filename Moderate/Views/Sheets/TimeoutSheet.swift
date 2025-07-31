import SwiftUI

struct TimeoutSheet: View {
    let userId: Int
    let username: String
    let channelSlug: String
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @EnvironmentObject var moderationService: ModerationService
    @State private var selectedDuration = 60
    @State private var reason = ""
    @State private var isPerformingAction = false
    
    private let durations = [
        (60, "1 dakika"),
        (300, "5 dakika"),
        (600, "10 dakika"),
        (1800, "30 dakika"),
        (3600, "1 saat"),
        (7200, "2 saat"),
        (21600, "6 saat"),
        (86400, "24 saat")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Kullanıcıyı Sustur")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("@\(username) kullanıcısını belirtilen süre boyunca susturacaksınız.")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Süre Seçin")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(durations, id: \.0) { duration, label in
                            DurationButton(
                                duration: duration,
                                label: label,
                                isSelected: selectedDuration == duration
                            ) {
                                selectedDuration = duration
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sebep (İsteğe bağlı)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Susturma sebebini yazın...", text: $reason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .colorScheme(.dark)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: performTimeout) {
                        HStack {
                            if isPerformingAction {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "clock")
                            }
                            
                            Text(isPerformingAction ? "Susturuluyor..." : "Sustur")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
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
            .navigationTitle("Sustur")
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
    
    private func performTimeout() {
        isPerformingAction = true
        
        Task {
            let success = await moderationService.timeoutUser(
                userId: userId,
                channelSlug: channelSlug,
                duration: selectedDuration,
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

struct DurationButton: View {
    let duration: Int
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.orange : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(10)
        }
    }
}

#Preview {
    TimeoutSheet(
        userId: 123,
        username: "testuser",
        channelSlug: "test-channel",
        isPresented: .constant(true),
        onComplete: {}
    )
    .environmentObject(ModerationService(authService: AuthService()))
    .preferredColorScheme(.dark)
}