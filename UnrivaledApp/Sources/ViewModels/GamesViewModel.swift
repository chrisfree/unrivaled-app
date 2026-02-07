import Foundation
import SwiftUI

@MainActor
class GamesViewModel: ObservableObject {
    @Published var allGames: [Game] = []
    @Published var liveGames: [Game] = []
    @Published var isLoading = false
    @Published var error: String?
    
    @AppStorage("favoriteTeamID", store: UserDefaults(suiteName: "group.com.unrivaled.app"))
    var favoriteTeamID: String = ""
    
    private let api = APIService.shared
    private var liveUpdateTask: Task<Void, Never>?
    
    var upcomingGames: [Game] {
        allGames
            .filter { !$0.isCompleted && !$0.isLive && $0.date >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
    }
    
    var completedGames: [Game] {
        allGames
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
    }
    
    var hasLiveGames: Bool {
        !liveGames.isEmpty
    }
    
    var favoriteTeamUpcoming: [Game] {
        guard !favoriteTeamID.isEmpty else { return upcomingGames }
        return upcomingGames.filter {
            $0.homeTeam.id == favoriteTeamID || $0.awayTeam.id == favoriteTeamID
        }
    }
    
    var favoriteTeamResults: [Game] {
        guard !favoriteTeamID.isEmpty else { return completedGames }
        return completedGames.filter {
            $0.homeTeam.id == favoriteTeamID || $0.awayTeam.id == favoriteTeamID
        }
    }
    
    var nextGame: Game? {
        upcomingGames.first
    }
    
    var nextFavoriteGame: Game? {
        favoriteTeamUpcoming.first
    }
    
    var lastResult: Game? {
        completedGames.first
    }
    
    // MARK: - Data Fetching
    
    func loadGames() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        
        do {
            // Fetch from all endpoints and combine (free tier has limits per endpoint)
            async let seasonGames = api.fetchSeasonGames()
            async let upcomingGames = api.fetchUpcomingGames()
            async let recentGames = api.fetchRecentResults()
            async let liveGamesResult = api.fetchLiveGamesWithFallback()
            
            let (season, upcoming, recent, live) = try await (seasonGames, upcomingGames, recentGames, liveGamesResult)
            
            // Store live games separately
            self.liveGames = live
            
            // Combine and deduplicate by game ID
            var gameDict: [String: Game] = [:]
            for game in season { gameDict[game.id] = game }
            for game in upcoming { gameDict[game.id] = game }
            for game in recent { gameDict[game.id] = game }
            
            // Update with live data if available
            for game in live { gameDict[game.id] = game }
            
            self.allGames = Array(gameDict.values)
            
            // Save to widget storage
            let widgetProvider = WidgetDataProvider.shared
            widgetProvider.saveUpcomingGames(self.upcomingGames)
            widgetProvider.saveRecentGames(Array(completedGames.prefix(5)))
            
            // Start live update polling if there are live games
            if !live.isEmpty {
                startLiveUpdates()
            }
        } catch {
            self.error = "Failed to load games: \(error.localizedDescription)"
            print("API Error: \(error)")
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await api.clearCache()
        await loadGames()
    }
    
    // MARK: - Live Updates
    
    func startLiveUpdates() {
        liveUpdateTask?.cancel()
        liveUpdateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                guard !Task.isCancelled else { break }
                
                do {
                    let live = try await api.fetchLiveGames()
                    await MainActor.run {
                        self.liveGames = live
                        // Update allGames with live data
                        for game in live {
                            if let index = self.allGames.firstIndex(where: { $0.id == game.id }) {
                                self.allGames[index] = game
                            }
                        }
                    }
                    
                    // Stop polling if no more live games
                    if live.isEmpty {
                        break
                    }
                } catch {
                    print("Live update error: \(error)")
                }
            }
        }
    }
    
    func stopLiveUpdates() {
        liveUpdateTask?.cancel()
        liveUpdateTask = nil
    }
    
    // MARK: - Favorite Team
    
    var favoriteTeam: Team? {
        guard !favoriteTeamID.isEmpty else { return nil }
        return Team.find(byId: favoriteTeamID)
    }
    
    func setFavoriteTeam(_ team: Team?) {
        favoriteTeamID = team?.id ?? ""
        WidgetDataProvider.shared.favoriteTeamID = team?.id
    }
}
