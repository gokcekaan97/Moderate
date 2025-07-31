import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Kick Moderation Panel")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Kick hesabınızla giriş yaparak moderatör olduğunuz kanalları yönetebilirsiniz.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    print("🚀 Login button tapped")
                    authService.startAuthentication()
                }) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.key")
                        }
                        
                        Text(authService.isLoading ? "Giriş yapılıyor..." : "Kick ile Giriş Yap")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(authService.isLoading)
                
                Text("Giriş yaptığınızda, chat:read, chat:moderate, user:read, channel:write ve channel:read izinleri alınacaktır.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .alert("Giriş Hatası", isPresented: $showErrorAlert) {
            Button("Tamam") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Debug Info", isPresented: $showDebugAlert) {
            Button("Tamam") { }
        } message: {
            Text(debugMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .authenticationError)) { notification in
            if let error = notification.object as? String {
                errorMessage = error
                showErrorAlert = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .debugMessage)) { notification in
            if let debug = notification.object as? String {
                debugMessage = debug
                showDebugAlert = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
}