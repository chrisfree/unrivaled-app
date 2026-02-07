import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GamesViewModel()
    
    var body: some View {
        TabView {
            ScheduleView(viewModel: viewModel)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            
            ResultsView(viewModel: viewModel)
                .tabItem {
                    Label("Results", systemImage: "sportscourt")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.orange)
        .task {
            await viewModel.loadGames()
        }
    }
}

// MARK: - Schedule View

struct ScheduleView: View {
    @ObservedObject var viewModel: GamesViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.allGames.isEmpty {
                    ProgressView("Loading schedule...")
                } else if viewModel.upcomingGames.isEmpty {
                    ContentUnavailableView(
                        "No Upcoming Games",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Check back later for the schedule")
                    )
                } else {
                    List {
                        if let fav = viewModel.favoriteTeam, !viewModel.favoriteTeamUpcoming.isEmpty {
                            Section {
                                ForEach(viewModel.favoriteTeamUpcoming.prefix(3)) { game in
                                    GameRow(game: game, highlightTeamID: fav.id)
                                }
                            } header: {
                                HStack {
                                    Text(fav.shortName)
                                    Spacer()
                                    Text("FAVORITE")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Section("All Upcoming") {
                            ForEach(viewModel.upcomingGames) { game in
                                GameRow(game: game)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if let error = viewModel.error {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                            .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Results View

struct ResultsView: View {
    @ObservedObject var viewModel: GamesViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.allGames.isEmpty {
                    ProgressView("Loading results...")
                } else if viewModel.completedGames.isEmpty {
                    ContentUnavailableView(
                        "No Results Yet",
                        systemImage: "sportscourt",
                        description: Text("Games haven't been played yet")
                    )
                } else {
                    List {
                        if let fav = viewModel.favoriteTeam, !viewModel.favoriteTeamResults.isEmpty {
                            Section {
                                ForEach(viewModel.favoriteTeamResults.prefix(3)) { game in
                                    ResultRow(game: game, highlightTeamID: fav.id)
                                }
                            } header: {
                                HStack {
                                    Text(fav.shortName)
                                    Spacer()
                                    Text("FAVORITE")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Section("All Results") {
                            ForEach(viewModel.completedGames) { game in
                                ResultRow(game: game)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Results")
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: GamesViewModel
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var selectedTeamID: String = ""
    @State private var apiKeyInput: String = ""
    @State private var showingAPIKeyInfo = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Favorite Team") {
                    Picker("Team", selection: $selectedTeamID) {
                        Text("None").tag("")
                        ForEach(Team.allTeams) { team in
                            Text(team.name).tag(team.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedTeamID) { _, newValue in
                        let team = newValue.isEmpty ? nil : Team.find(byId: newValue)
                        viewModel.setFavoriteTeam(team)
                    }
                    
                    if let team = viewModel.favoriteTeam {
                        HStack {
                            AsyncImage(url: URL(string: team.badgeURL ?? "")) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "sportscourt.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                            .frame(width: 40, height: 40)
                            
                            Text(team.name)
                                .font(.headline)
                        }
                    }
                }
                
                Section {
                    HStack {
                        SecureField("API Key", text: $apiKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        if apiKeyInput != apiKeyManager.apiKey {
                            Button("Save") {
                                apiKeyManager.apiKey = apiKeyInput.isEmpty ? "123" : apiKeyInput
                                Task {
                                    await viewModel.refresh()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        if apiKeyManager.isPremium {
                            Label("Premium", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Free (Limited)", systemImage: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        showingAPIKeyInfo = true
                    } label: {
                        Label("Get Premium API Key", systemImage: "arrow.up.right")
                    }
                } header: {
                    Text("TheSportsDB API")
                } footer: {
                    Text("Free tier shows limited games. Premium ($9/mo) unlocks full schedule and live scores.")
                }
                
                Section("About") {
                    LabeledContent("League", value: "Unrivaled Basketball")
                    LabeledContent("Season", value: "2026")
                    LabeledContent("Data", value: "TheSportsDB")
                }
                
                Section {
                    Button("Refresh Data") {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                selectedTeamID = viewModel.favoriteTeamID
                apiKeyInput = apiKeyManager.apiKey
            }
            .sheet(isPresented: $showingAPIKeyInfo) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TheSportsDB Premium")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Get full access to all games, scores, and live updates for $9/month.")
                            .foregroundStyle(.secondary)
                        
                        Link(destination: URL(string: "https://www.thesportsdb.com/pricing")!) {
                            Label("Sign Up at TheSportsDB.com", systemImage: "globe")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        
                        Text("After signing up, copy your API key from your profile page and paste it in Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingAPIKeyInfo = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    ContentView()
}
