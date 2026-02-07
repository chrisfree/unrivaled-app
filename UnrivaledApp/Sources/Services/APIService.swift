import Foundation

// MARK: - API Service

actor APIService {
    static let shared = APIService()
    
    private let baseURL = "https://www.thesportsdb.com/api/v1/json/123"
    private let leagueID = "5622"
    private let currentSeason = "2026"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    private var cache = APICache()
    
    // MARK: - Public Methods
    
    /// Fetch all games for the current season
    func fetchSeasonGames() async throws -> [Game] {
        let cacheKey = "season_\(currentSeason)"
        if let cached: [Game] = cache.get(key: cacheKey) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/eventsseason.php?id=\(leagueID)&s=\(currentSeason)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(EventsResponse.self, from: data)
        let games = response.events?.map { $0.game } ?? []
        
        cache.set(key: cacheKey, value: games, ttl: 300) // 5 min cache
        return games
    }
    
    /// Fetch upcoming games
    func fetchUpcomingGames() async throws -> [Game] {
        let cacheKey = "upcoming"
        if let cached: [Game] = cache.get(key: cacheKey) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/eventsnextleague.php?id=\(leagueID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(EventsResponse.self, from: data)
        let games = response.events?.map { $0.game } ?? []
        
        cache.set(key: cacheKey, value: games, ttl: 300)
        return games
    }
    
    /// Fetch recent results
    func fetchRecentResults() async throws -> [Game] {
        let cacheKey = "results"
        if let cached: [Game] = cache.get(key: cacheKey) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/eventspastleague.php?id=\(leagueID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(EventsResponse.self, from: data)
        let games = response.events?.map { $0.game } ?? []
        
        cache.set(key: cacheKey, value: games, ttl: 300)
        return games
    }
    
    /// Fetch all teams
    func fetchTeams() async throws -> [Team] {
        let cacheKey = "teams"
        if let cached: [Team] = cache.get(key: cacheKey) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/search_all_teams.php?l=Unrivaled_Basketball")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TeamsResponse.self, from: data)
        let teams = response.teams?.map { $0.team } ?? Team.allTeams
        
        cache.set(key: cacheKey, value: teams, ttl: 3600) // 1 hour cache
        return teams
    }
    
    /// Fetch standings
    func fetchStandings() async throws -> [Standing] {
        let url = URL(string: "\(baseURL)/lookuptable.php?l=\(leagueID)&s=\(currentSeason)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TableResponse.self, from: data)
        return response.table ?? []
    }
    
    /// Clear cache
    func clearCache() {
        cache.clear()
    }
}

// MARK: - Simple Cache

private struct APICache {
    private var storage: [String: CacheEntry] = [:]
    
    struct CacheEntry {
        let data: Any
        let expiry: Date
    }
    
    mutating func get<T>(key: String) -> T? {
        guard let entry = storage[key],
              entry.expiry > Date() else {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.data as? T
    }
    
    mutating func set<T>(key: String, value: T, ttl: TimeInterval) {
        storage[key] = CacheEntry(data: value, expiry: Date().addingTimeInterval(ttl))
    }
    
    mutating func clear() {
        storage.removeAll()
    }
}

// MARK: - Widget Data Provider

/// Shared data for widgets (uses App Group)
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let suiteName = "group.com.unrivaled.app"
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    // Keys
    private let upcomingGamesKey = "upcoming_games"
    private let recentGamesKey = "recent_games"
    private let favoriteTeamKey = "favorite_team"
    private let lastUpdateKey = "last_update"
    
    // MARK: - Favorite Team
    
    var favoriteTeamID: String? {
        get { defaults?.string(forKey: favoriteTeamKey) }
        set { defaults?.set(newValue, forKey: favoriteTeamKey) }
    }
    
    var favoriteTeam: Team? {
        guard let id = favoriteTeamID else { return nil }
        return Team.find(byId: id)
    }
    
    // MARK: - Game Data
    
    func saveUpcomingGames(_ games: [Game]) {
        guard let data = try? JSONEncoder().encode(games) else { return }
        defaults?.set(data, forKey: upcomingGamesKey)
        defaults?.set(Date(), forKey: lastUpdateKey)
    }
    
    func loadUpcomingGames() -> [Game] {
        guard let data = defaults?.data(forKey: upcomingGamesKey),
              let games = try? JSONDecoder().decode([Game].self, from: data) else {
            return []
        }
        return games
    }
    
    func saveRecentGames(_ games: [Game]) {
        guard let data = try? JSONEncoder().encode(games) else { return }
        defaults?.set(data, forKey: recentGamesKey)
    }
    
    func loadRecentGames() -> [Game] {
        guard let data = defaults?.data(forKey: recentGamesKey),
              let games = try? JSONDecoder().decode([Game].self, from: data) else {
            return []
        }
        return games
    }
    
    var lastUpdate: Date? {
        defaults?.object(forKey: lastUpdateKey) as? Date
    }
}
