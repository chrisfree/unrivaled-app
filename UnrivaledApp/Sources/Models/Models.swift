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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: dateEvent) ?? Date()
        
        var gameDate = date
        if let timeStr = strTime, !timeStr.isEmpty {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ssXXX"
            if let time = timeFormatter.date(from: timeStr) {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                gameDate = calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                                        minute: timeComponents.minute ?? 0, 
                                        second: 0, of: date) ?? date
            }
        }
        
        let homeScore = intHomeScore.flatMap { Int($0) }
        let awayScore = intAwayScore.flatMap { Int($0) }
        let isCompleted = homeScore != nil && awayScore != nil
        
        return Game(
            id: idEvent,
            homeTeam: Team(id: idHomeTeam ?? "", name: strHomeTeam, badgeURL: strHomeTeamBadge),
            awayTeam: Team(id: idAwayTeam ?? "", name: strAwayTeam, badgeURL: strAwayTeamBadge),
            homeScore: homeScore,
            awayScore: awayScore,
            date: gameDate,
            status: isCompleted ? .completed : (strStatus == "NS" ? .scheduled : .scheduled),
            thumbnailURL: strThumb
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
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else {
            return "vs"
        }
        return "\(home) - \(away)"
    }
    
    var winner: Team? {
        guard let home = homeScore, let away = awayScore else { return nil }
        if home > away { return homeTeam }
        if away > home { return awayTeam }
        return nil
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
