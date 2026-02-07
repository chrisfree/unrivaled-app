import Foundation
import SwiftUI

@MainActor
class GamesViewModel: ObservableObject {
    @Published var allGames: [Game] = []
    @Published var isLoading = false
    @Published var error: String?
    
    @AppStorage("favoriteTeamID", store: UserDefaults(suiteName: "group.com.unrivaled.app"))
    var favoriteTeamID: String = ""
    
    private let api = APIService.shared
    
    var upcomingGames: [Game] {
        allGames
            .filter { !$0.isCompleted && $0.date >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
    }
    
    var completedGames: [Game] {
        allGames
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
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
            
            let (season, upcoming, recent) = try await (seasonGames, upcomingGames, recentGames)
            
            // Combine and deduplicate by game ID
            var gameDict: [String: Game] = [:]
            for game in season { gameDict[game.id] = game }
            for game in upcoming { gameDict[game.id] = game }
            for game in recent { gameDict[game.id] = game }
            
            self.allGames = Array(gameDict.values)
            
            // Save to widget storage
            let widgetProvider = WidgetDataProvider.shared
            widgetProvider.saveUpcomingGames(self.upcomingGames)
            widgetProvider.saveRecentGames(Array(completedGames.prefix(5)))
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
