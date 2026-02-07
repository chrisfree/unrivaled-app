import Foundation
import SwiftSoup

/// Scrapes live game data from unrivaled.basketball as a fallback
/// when TheSportsDB doesn't have live data
actor LiveScoreScraper {
    static let shared = LiveScoreScraper()
    
    private let baseURL = "https://www.unrivaled.basketball"
    
    struct ScrapedGame {
        let homeTeam: String
        let awayTeam: String
        let homeScore: Int
        let awayScore: Int
        let isLive: Bool
        let status: String // "Live", "Final", "7:30 PM ET"
        let gameURL: String?
    }
    
    /// Fetches live games from the Unrivaled website
    func fetchLiveGames() async throws -> [ScrapedGame] {
        let url = URL(string: baseURL)!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScraperError.invalidHTML
        }
        
        return try parseGames(from: html)
    }
    
    /// Parses the HTML to extract game data
    private func parseGames(from html: String) throws -> [ScrapedGame] {
        let doc = try SwiftSoup.parse(html)
        var games: [ScrapedGame] = []
        
        // Find all game links - they have the pattern /game/xxxxx
        let gameLinks = try doc.select("a[href^=/game/]")
        
        for link in gameLinks {
            // Get the game URL
            let href = try link.attr("href")
            let gameURL = baseURL + href
            
            // Get the text content to parse teams and scores
            let text = try link.text()
            
            // Check if this is a live game
            let isLive = text.lowercased().contains("live")
            let isFinal = text.lowercased().contains("final")
            
            // Parse based on format: "Live TNT/truTV Lunar Owls 17 Laces 28"
            // or "Final Hive 70 Breeze 68"
            if let game = parseGameText(text, gameURL: gameURL, isLive: isLive, isFinal: isFinal) {
                games.append(game)
            }
        }
        
        // Deduplicate by gameURL
        var seen = Set<String>()
        return games.filter { game in
            guard let url = game.gameURL else { return true }
            if seen.contains(url) { return false }
            seen.insert(url)
            return true
        }
    }
    
    /// Parses game text like "Live TNT/truTV Lunar Owls 17 Laces 28"
    private func parseGameText(_ text: String, gameURL: String?, isLive: Bool, isFinal: Bool) -> ScrapedGame? {
        // Known team names
        let teamNames = [
            "Breeze", "Hive", "Laces", "Lunar Owls", 
            "Mist", "Phantom", "Rose", "Vinyl"
        ]
        
        var foundTeams: [(name: String, score: Int?)] = []
        var remaining = text
        
        // Find each team and the number following it
        for teamName in teamNames {
            if let range = remaining.range(of: teamName, options: .caseInsensitive) {
                // Get text after team name to find score
                let afterTeam = String(remaining[range.upperBound...])
                let score = extractFirstNumber(from: afterTeam)
                foundTeams.append((name: teamName, score: score))
            }
        }
        
        // Need exactly 2 teams
        guard foundTeams.count == 2 else { return nil }
        
        let status: String
        if isLive {
            status = "Live"
        } else if isFinal {
            status = "Final"
        } else {
            status = "Scheduled"
        }
        
        return ScrapedGame(
            homeTeam: foundTeams[0].name,
            awayTeam: foundTeams[1].name,
            homeScore: foundTeams[0].score ?? 0,
            awayScore: foundTeams[1].score ?? 0,
            isLive: isLive,
            status: status,
            gameURL: gameURL
        )
    }
    
    /// Extracts the first number from a string
    private func extractFirstNumber(from text: String) -> Int? {
        let pattern = #"^\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[range])
    }
    
    /// Converts scraped games to app Game models
    func convertToGames(_ scraped: [ScrapedGame]) -> [Game] {
        scraped.compactMap { sg -> Game? in
            guard let homeTeam = Team.find(byName: sg.homeTeam),
                  let awayTeam = Team.find(byName: sg.awayTeam) else {
                return nil
            }
            
            let status: GameStatus
            if sg.isLive {
                status = .live
            } else if sg.status == "Final" {
                status = .completed
            } else {
                status = .scheduled
            }
            
            return Game(
                id: "scraped_\(homeTeam.id)_\(awayTeam.id)_\(Date().timeIntervalSince1970)",
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                homeScore: sg.homeScore,
                awayScore: sg.awayScore,
                date: Date(),
                status: status,
                thumbnailURL: nil,
                progress: sg.isLive ? "Live" : nil
            )
        }
    }
    
    enum ScraperError: Error {
        case invalidHTML
        case parsingFailed
    }
}

// MARK: - Integration with APIService

extension APIService {
    /// Fetches live games, falling back to scraper if API has no data
    func fetchLiveGamesWithFallback() async throws -> [Game] {
        // First try the API
        let apiGames = try await fetchLiveGames()
        if !apiGames.isEmpty {
            return apiGames
        }
        
        // Fall back to scraping
        do {
            let scraped = try await LiveScoreScraper.shared.fetchLiveGames()
            let liveOnly = scraped.filter { $0.isLive }
            return LiveScoreScraper.shared.convertToGames(liveOnly)
        } catch {
            print("Scraper fallback failed: \(error)")
            return []
        }
    }
}
