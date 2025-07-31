import SwiftUI

struct ChannelEditSheet: View {
    let channel: Channel
    @Binding var isPresented: Bool
    
    @EnvironmentObject var channelService: ChannelService
    @State private var title: String
    @State private var selectedCategory: Category?
    @State private var language: String
    @State private var isMature: Bool
    @State private var tags: String
    @State private var categories: [Category] = []
    @State private var categorySearchText = ""
    @State private var isLoadingCategories = false
    @State private var isSaving = false
    @State private var showingCategoryPicker = false
    
    init(channel: Channel, isPresented: Binding<Bool>) {
        self.channel = channel
        self._isPresented = isPresented
        self._title = State(initialValue: channel.message ?? "")
        self._selectedCategory = State(initialValue: channel.category)
        self._language = State(initialValue: channel.language ?? "tr")
        self._isMature = State(initialValue: channel.isMature)
        self._tags = State(initialValue: channel.tags?.joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Başlık")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Kanal başlığını girin...", text: $title, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                            .lineLimit(2...4)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kategori")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            showingCategoryPicker = true
                        }) {
                            HStack {
                                Text(selectedCategory?.name ?? "Kategori seçin")
                                    .foregroundColor(selectedCategory != nil ? .white : .gray)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dil")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Picker("Dil", selection: $language) {
                            Text("Türkçe").tag("tr")
                            Text("English").tag("en")
                            Text("Español").tag("es")
                            Text("Français").tag("fr")
                            Text("Deutsch").tag("de")
                            Text("Português").tag("pt")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Etiketler")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Etiketleri virgülle ayırın...", text: $tags)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                        
                        Text("Örnek: oyun, eğlence, sohbet")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button(action: {
                                isMature.toggle()
                            }) {
                                Image(systemName: isMature ? "checkmark.square.fill" : "square")
                                    .foregroundColor(isMature ? .orange : .gray)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Yetişkin İçeriği")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("18+ içerik barındırıyor")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Kanal Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(0.8)
                        } else {
                            Text("Kaydet")
                        }
                    }
                    .foregroundColor(.green)
                    .disabled(isSaving)
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(
                selectedCategory: $selectedCategory,
                isPresented: $showingCategoryPicker
            )
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        isLoadingCategories = true
        Task {
            let fetchedCategories = await channelService.fetchCategories()
            
            await MainActor.run {
                self.categories = fetchedCategories
                self.isLoadingCategories = false
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        let tagsArray = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let update = ChannelUpdate(
            title: title.isEmpty ? nil : title,
            categoryId: selectedCategory?.id,
            language: language,
            isMature: isMature,
            tags: tagsArray.isEmpty ? nil : tagsArray
        )
        
        Task {
            let success = await channelService.updateChannel(channel.slug, update: update)
            
            await MainActor.run {
                isSaving = false
                
                if success {
                    isPresented = false
                }
            }
        }
    }
}

struct CategoryPickerSheet: View {
    @Binding var selectedCategory: Category?
    @Binding var isPresented: Bool
    
    @EnvironmentObject var channelService: ChannelService
    @State private var categories: [Category] = []
    @State private var searchText = ""
    @State private var isLoading = false
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: {
                    searchCategories()
                })
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        
                        Text("Kategoriler yükleniyor...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredCategories) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                selectedCategory = category
                                isPresented = false
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.black)
                }
            }
            .background(Color.black)
            .navigationTitle("Kategori Seç")
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
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        isLoading = true
        Task {
            let fetchedCategories = await channelService.fetchCategories()
            
            await MainActor.run {
                self.categories = fetchedCategories
                self.isLoading = false
            }
        }
    }
    
    private func searchCategories() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        Task {
            let fetchedCategories = await channelService.fetchCategories(search: searchText)
            
            await MainActor.run {
                self.categories = fetchedCategories
                self.isLoading = false
            }
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let description = category.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                TextField("Kategori ara...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .colorScheme(.dark)
                    .onSubmit {
                        onSearchButtonClicked()
                    }
                
                Button("Ara", action: onSearchButtonClicked)
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
}

#Preview {
    ChannelEditSheet(
        channel: Channel(
            id: 1,
            userId: 1,
            slug: "test",
            playbackUrl: nil,
            vods: false,
            followersCount: 100,
            user: User(
                id: 1,
                username: "test",
                slug: "test",
                profilePic: nil,
                verified: nil,
                followersCount: nil,
                bio: nil,
                country: nil,
                state: nil,
                city: nil,
                instagram: nil,
                twitter: nil,
                youtube: nil,
                discord: nil,
                tiktok: nil,
                facebook: nil
            ),
            isLive: false,
            category: nil,
            tags: nil,
            viewersCount: nil,
            chatroom: nil,
            recentMessage: nil,
            thumbnail: nil,
            duration: nil,
            language: nil,
            isMature: false,
            viewerCountVisible: true,
            chatModeOld: nil,
            chatMode: nil,
            slowMode: false,
            subscriberMode: false,
            followersMode: false,
            emotesMode: true,
            message: nil,
            offlinebannerImage: nil
        ),
        isPresented: .constant(true)
    )
    .environmentObject(ChannelService(authService: AuthService()))
    .preferredColorScheme(.dark)
}