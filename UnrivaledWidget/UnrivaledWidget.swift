import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct GameEntry: TimelineEntry {
    let date: Date
    let game: WidgetGame?
    let teamName: String?
    let configuration: ConfigurationAppIntent
}

struct WidgetGame {
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let gameDate: Date
    let isCompleted: Bool
    
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else { return "vs" }
        return "\(home) - \(away)"
    }
}

// MARK: - Configuration Intent

import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Team"
    static var description = IntentDescription("Choose your favorite team")
    
    @Parameter(title: "Team")
    var team: TeamOption?
}

enum TeamOption: String, AppEnum {
    case breeze = "Breeze"
    case hive = "Hive"
    case laces = "Laces"
    case lunarOwls = "Lunar Owls"
    case mist = "Mist"
    case phantom = "Phantom"
    case rose = "Rose"
    case vinyl = "Vinyl"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Team"
    
    static var caseDisplayRepresentations: [TeamOption: DisplayRepresentation] = [
        .breeze: "Breeze BC",
        .hive: "Hive BC",
        .laces: "Laces BC",
        .lunarOwls: "Lunar Owls BC",
        .mist: "Mist BC",
        .phantom: "Phantom BC",
        .rose: "Rose BC",
        .vinyl: "Vinyl BC"
    ]
    
    var teamID: String {
        switch self {
        case .breeze: return "154048"
        case .hive: return "154049"
        case .laces: return "151477"
        case .lunarOwls: return "150651"
        case .mist: return "151962"
        case .phantom: return "151478"
        case .rose: return "151481"
        case .vinyl: return "150736"
        }
    }
}

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    private let suiteName = "group.com.unrivaled.app"
    
    func placeholder(in context: Context) -> GameEntry {
        GameEntry(
            date: Date(),
            game: WidgetGame(
                homeTeam: "Breeze",
                awayTeam: "Hive",
                homeScore: nil,
                awayScore: nil,
                gameDate: Date().addingTimeInterval(86400),
                isCompleted: false
            ),
            teamName: nil,
            configuration: ConfigurationAppIntent()
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> GameEntry {
        await getEntry(for: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<GameEntry> {
        let entry = await getEntry(for: configuration)
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func getEntry(for configuration: ConfigurationAppIntent) async -> GameEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        
        // Try to load cached games
        guard let data = defaults?.data(forKey: "upcoming_games"),
              let games = try? JSONDecoder().decode([CachedGame].self, from: data) else {
            return GameEntry(date: Date(), game: nil, teamName: configuration.team?.rawValue, configuration: configuration)
        }
        
        // Filter by team if selected
        let filteredGames: [CachedGame]
        if let team = configuration.team {
            filteredGames = games.filter { 
                $0.homeTeam.contains(team.rawValue) || $0.awayTeam.contains(team.rawValue)
            }
        } else {
            filteredGames = games
        }
        
        guard let nextGame = filteredGames.first else {
            return GameEntry(date: Date(), game: nil, teamName: configuration.team?.rawValue, configuration: configuration)
        }
        
        let widgetGame = WidgetGame(
            homeTeam: shortName(nextGame.homeTeam),
            awayTeam: shortName(nextGame.awayTeam),
            homeScore: nextGame.homeScore,
            awayScore: nextGame.awayScore,
            gameDate: nextGame.date,
            isCompleted: nextGame.homeScore != nil
        )
        
        return GameEntry(
            date: Date(),
            game: widgetGame,
            teamName: configuration.team?.rawValue,
            configuration: configuration
        )
    }
    
    private func shortName(_ name: String) -> String {
        name.replacingOccurrences(of: " BC", with: "")
    }
}

// Cached game struct for decoding
private struct CachedGame: Codable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, homeScore, awayScore, date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        // Handle nested team objects
        if let homeTeamObj = try? container.decode(TeamInfo.self, forKey: .homeTeam) {
            homeTeam = homeTeamObj.name
        } else {
            homeTeam = try container.decode(String.self, forKey: .homeTeam)
        }
        
        if let awayTeamObj = try? container.decode(TeamInfo.self, forKey: .awayTeam) {
            awayTeam = awayTeamObj.name
        } else {
            awayTeam = try container.decode(String.self, forKey: .awayTeam)
        }
        
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
        date = try container.decode(Date.self, forKey: .date)
    }
}

private struct TeamInfo: Codable {
    let name: String
}

// MARK: - Widget Views

struct UnrivaledWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: GameEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "basketball.fill")
                    .foregroundStyle(.orange)
                Text("UNRIVALED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let game = entry.game {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.homeTeam)
                        .font(.headline)
                    Text(game.awayTeam)
                        .font(.headline)
                }
                
                Spacer()
                
                if game.isCompleted {
                    Text(game.scoreDisplay)
                        .font(.title3)
                        .fontWeight(.bold)
                } else {
                    Text(game.gameDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Spacer()
                Text("No upcoming games")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: GameEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Next game
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "basketball.fill")
                        .foregroundStyle(.orange)
                    Text("NEXT GAME")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                
                if let game = entry.game {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.homeTeam)
                                .font(.headline)
                            Text(game.awayTeam)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        if game.isCompleted, let home = game.homeScore, let away = game.awayScore {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(home)")
                                    .font(.headline)
                                Text("\(away)")
                                    .font(.headline)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !game.isCompleted {
                        Text(game.gameDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Spacer()
                    Text("No upcoming games")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Right side - Team filter or info
            VStack(alignment: .leading, spacing: 8) {
                if let teamName = entry.teamName {
                    Text(teamName.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    Spacer()
                    
                    Text("Favorite Team")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("UNRIVALED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Women's 3v3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct UnrivaledWidget: Widget {
    let kind: String = "UnrivaledWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            UnrivaledWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Unrivaled Schedule")
        .description("See upcoming games and scores")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct UnrivaledWidgetBundle: WidgetBundle {
    var body: some Widget {
        UnrivaledWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    UnrivaledWidget()
} timeline: {
    GameEntry(
        date: Date(),
        game: WidgetGame(
            homeTeam: "Breeze",
            awayTeam: "Hive",
            homeScore: nil,
            awayScore: nil,
            gameDate: Date().addingTimeInterval(86400),
            isCompleted: false
        ),
        teamName: nil,
        configuration: ConfigurationAppIntent()
    )
}

#Preview("Medium", as: .systemMedium) {
    UnrivaledWidget()
} timeline: {
    GameEntry(
        date: Date(),
        game: WidgetGame(
            homeTeam: "Breeze",
            awayTeam: "Hive",
            homeScore: 78,
            awayScore: 65,
            gameDate: Date(),
            isCompleted: true
        ),
        teamName: "Breeze",
        configuration: ConfigurationAppIntent()
    )
}
