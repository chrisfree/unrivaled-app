import Foundation

// MARK: - API Response Models

struct EventsResponse: Codable {
    let events: [APIEvent]?
}

struct TeamsResponse: Codable {
    let teams: [APITeam]?
}

struct TableResponse: Codable {
    let table: [Standing]?
}

// MARK: - API Event

struct APIEvent: Codable, Identifiable {
    let idEvent: String
    let strEvent: String
    let strHomeTeam: String
    let strAwayTeam: String
    let intHomeScore: String?
    let intAwayScore: String?
    let dateEvent: String
    let strTime: String?
    let strTimestamp: String?
    let strThumb: String?
    let strStatus: String?
    let idHomeTeam: String?
    let idAwayTeam: String?
    let strHomeTeamBadge: String?
    let strAwayTeamBadge: String?
    
    var id: String { idEvent }
    
    var game: Game {
        var gameDate: Date? = nil
        var hasValidTime = false
        
        // Try to parse timestamp first (most reliable when present)
        // Format: "2026-02-07T00:30:00" - this is UTC time
        if let timestamp = strTimestamp, timestamp.count >= 19 {
            let cleanTimestamp = String(timestamp.prefix(19))
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            isoFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let parsed = isoFormatter.date(from: cleanTimestamp) {
                gameDate = parsed
                hasValidTime = true
            }
        }
        
        // Fallback: try dateEvent + strTime
        if gameDate == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            
            if let baseDateParsed = dateFormatter.date(from: dateEvent) {
                var finalDate = baseDateParsed
                
                // Try to add time if available
                if let timeStr = strTime, !timeStr.isEmpty {
                    let timeParts = timeStr.components(separatedBy: ":")
                    if timeParts.count >= 2,
                       let hour = Int(timeParts[0]),
                       let minute = Int(timeParts[1]) {
                        var components = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: baseDateParsed)
                        components.hour = hour
                        components.minute = minute
                        components.second = 0
                        if let withTime = Calendar.current.date(from: components) {
                            finalDate = withTime
                            hasValidTime = true
                        }
                    }
                }
                
                gameDate = finalDate
            }
        }
        
        // Last resort: use current date (but flag as no valid time)
        let finalGameDate = gameDate ?? Date()
        
        let homeScore = intHomeScore.flatMap { Int($0) }
        let awayScore = intAwayScore.flatMap { Int($0) }
        
        // Determine status
        var status: GameStatus = .scheduled
        if let statusStr = strStatus?.lowercased() {
            if statusStr.contains("live") || statusStr.contains("progress") || statusStr == "1h" || statusStr == "2h" || statusStr == "ht" {
                status = .live
            } else if statusStr == "ft" || statusStr == "aet" || statusStr == "finished" {
                status = .completed
            }
        }
        // If we have scores but no live status, it's completed
        if status == .scheduled && homeScore != nil && awayScore != nil {
            status = .completed
        }
        
        return Game(
            id: idEvent,
            homeTeam: Team(id: idHomeTeam ?? "", name: strHomeTeam, badgeURL: strHomeTeamBadge),
            awayTeam: Team(id: idAwayTeam ?? "", name: strAwayTeam, badgeURL: strAwayTeamBadge),
            homeScore: homeScore,
            awayScore: awayScore,
            date: finalGameDate,
            status: status,
            thumbnailURL: strThumb,
            hasValidTime: hasValidTime
        )
    }
}

// MARK: - V2 Livescore Response

struct LivescoreResponse: Codable {
    let livescores: [APILivescore]?
}

struct APILivescore: Codable, Identifiable {
    let idEvent: String
    let strEvent: String
    let strHomeTeam: String
    let strAwayTeam: String
    let intHomeScore: String?
    let intAwayScore: String?
    let strProgress: String?
    let strStatus: String?
    let idHomeTeam: String?
    let idAwayTeam: String?
    let strHomeTeamBadge: String?
    let strAwayTeamBadge: String?
    let idLeague: String?
    let strLeague: String?
    
    var id: String { idEvent }
    
    var game: Game {
        let homeScore = intHomeScore.flatMap { Int($0) }
        let awayScore = intAwayScore.flatMap { Int($0) }
        
        return Game(
            id: idEvent,
            homeTeam: Team(id: idHomeTeam ?? "", name: strHomeTeam, badgeURL: strHomeTeamBadge),
            awayTeam: Team(id: idAwayTeam ?? "", name: strAwayTeam, badgeURL: strAwayTeamBadge),
            homeScore: homeScore,
            awayScore: awayScore,
            date: Date(),
            status: .live,
            thumbnailURL: nil,
            progress: strProgress
        )
    }
}

// MARK: - API Team

struct APITeam: Codable, Identifiable {
    let idTeam: String
    let strTeam: String
    let strTeamBadge: String?
    let strTeamLogo: String?
    let strDescriptionEN: String?
    
    var id: String { idTeam }
    
    var team: Team {
        Team(id: idTeam, name: strTeam, badgeURL: strTeamBadge, logoURL: strTeamLogo, description: strDescriptionEN)
    }
}

// MARK: - Standing

struct Standing: Codable, Identifiable {
    let idStanding: String?
    let strTeam: String
    let intPlayed: String?
    let intWin: String?
    let intLoss: String?
    let intGoalsFor: String?
    let intGoalsAgainst: String?
    let intPoints: String?
    let strTeamBadge: String?
    
    var id: String { idStanding ?? strTeam }
    var played: Int { Int(intPlayed ?? "0") ?? 0 }
    var wins: Int { Int(intWin ?? "0") ?? 0 }
    var losses: Int { Int(intLoss ?? "0") ?? 0 }
    var points: Int { Int(intPoints ?? "0") ?? 0 }
}

// MARK: - App Models

struct Team: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let badgeURL: String?
    var logoURL: String?
    var description: String?
    
    // Short name for display
    var shortName: String {
        name.replacingOccurrences(of: " BC", with: "")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.id == rhs.id
    }
}

struct Game: Codable, Identifiable {
    let id: String
    let homeTeam: Team
    let awayTeam: Team
    let homeScore: Int?
    let awayScore: Int?
    let date: Date
    let status: GameStatus
    let thumbnailURL: String?
    var progress: String? = nil  // e.g., "Q2 5:30", "Halftime"
    var hasValidTime: Bool = true  // false when API didn't provide time
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isLive: Bool {
        status == .live
    }
    
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else {
            return "vs"
        }
        return "\(home) - \(away)"
    }
    
    var winner: Team? {
        guard let home = homeScore, let away = awayScore, isCompleted else { return nil }
        if home > away { return homeTeam }
        if away > home { return awayTeam }
        return nil
    }
    
    /// Formatted time string - shows "TBD" if no valid time from API
    var timeDisplay: String {
        if !hasValidTime {
            return "TBD"
        }
        return date.formatted(date: .omitted, time: .shortened)
    }
    
    /// Formatted date in user's local timezone
    var dateDisplay: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum GameStatus: String, Codable {
    case scheduled
    case live
    case completed
}

// MARK: - Hardcoded Teams (fallback)

extension Team {
    static let allTeams: [Team] = [
        Team(id: "154048", name: "Breeze BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/breeze-bc.png"),
        Team(id: "154049", name: "Hive BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/hive-bc.png"),
        Team(id: "151477", name: "Laces BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/laces-bc.png"),
        Team(id: "150651", name: "Lunar Owls BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/lunar-owls-bc.png"),
        Team(id: "151962", name: "Mist BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/mist-bc.png"),
        Team(id: "151478", name: "Phantom BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/phantom-bc.png"),
        Team(id: "151481", name: "Rose BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/rose-bc.png"),
        Team(id: "150736", name: "Vinyl BC", badgeURL: "https://r2.thesportsdb.com/images/media/team/badge/vinyl-bc.png"),
    ]
    
    static func find(byId id: String) -> Team? {
        allTeams.first { $0.id == id }
    }
    
    static func find(byName name: String) -> Team? {
        allTeams.first { $0.name == name || $0.shortName == name }
    }
}
