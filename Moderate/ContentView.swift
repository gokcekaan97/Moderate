//
//  ContentView.swift
//  Moderate
//
//  Created by kaan gokcek on 31.07.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var channelService: ChannelService
    
    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                if let selectedChannel = channelService.selectedChannel {
                    MainTabView()
                } else {
                    ChannelSelectionView()
                }
            } else {
                LoginView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(ChannelService(authService: AuthService()))
        .environmentObject(ChatService(authService: AuthService()))
        .environmentObject(ModerationService(authService: AuthService()))
        .preferredColorScheme(.dark)
}
