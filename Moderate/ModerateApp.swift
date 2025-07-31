//
//  ModerateApp.swift
//  Moderate
//
//  Created by kaan gokcek on 31.07.2025.
//

import SwiftUI

@main
struct ModerateApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var channelService: ChannelService
    @StateObject private var chatService: ChatService
    @StateObject private var moderationService: ModerationService
    
    init() {
        let auth = AuthService()
        let channel = ChannelService(authService: auth)
        let chat = ChatService(authService: auth)
        let moderation = ModerationService(authService: auth)
        
        self._authService = StateObject(wrappedValue: auth)
        self._channelService = StateObject(wrappedValue: channel)
        self._chatService = StateObject(wrappedValue: chat)
        self._moderationService = StateObject(wrappedValue: moderation)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(channelService)
                .environmentObject(chatService)
                .environmentObject(moderationService)
                .preferredColorScheme(.dark)
        }
    }
}
