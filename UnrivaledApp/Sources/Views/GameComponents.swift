import SwiftUI

// MARK: - Live Game Row

struct LiveGameRow: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Live indicator
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
                
                if let progress = game.progress {
                    Text("• \(progress)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Teams with live score
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        AsyncImage(url: URL(string: game.homeTeam.badgeURL ?? "")) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(.gray.opacity(0.3))
                        }
                        .frame(width: 28, height: 28)
                        
                        Text(game.homeTeam.shortName)
                            .font(.headline)
                    }
                    
                    HStack {
                        AsyncImage(url: URL(string: game.awayTeam.badgeURL ?? "")) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(.gray.opacity(0.3))
                        }
                        .frame(width: 28, height: 28)
                        
                        Text(game.awayTeam.shortName)
                            .font(.headline)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(game.homeScore ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("\(game.awayScore ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Game Row (Upcoming)

struct GameRow: View {
    let game: Game
    var highlightTeamID: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date/Time
            HStack {
                Text(game.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(game.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Teams
            HStack(spacing: 12) {
                TeamBadge(team: game.homeTeam, isHighlighted: game.homeTeam.id == highlightTeamID)
                
                Text("vs")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                TeamBadge(team: game.awayTeam, isHighlighted: game.awayTeam.id == highlightTeamID)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Result Row (Completed)

struct ResultRow: View {
    let game: Game
    var highlightTeamID: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date
            Text(game.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Teams with Score
            HStack(spacing: 12) {
                ScoreTeamView(
                    team: game.homeTeam,
                    score: game.homeScore,
                    isWinner: game.winner?.id == game.homeTeam.id,
                    isHighlighted: game.homeTeam.id == highlightTeamID
                )
                
                Text("-")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                ScoreTeamView(
                    team: game.awayTeam,
                    score: game.awayScore,
                    isWinner: game.winner?.id == game.awayTeam.id,
                    isHighlighted: game.awayTeam.id == highlightTeamID,
                    alignment: .trailing
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Score Team View

struct ScoreTeamView: View {
    let team: Team
    let score: Int?
    let isWinner: Bool
    var isHighlighted: Bool = false
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            HStack(spacing: 8) {
                if alignment == .trailing {
                    scoreText
                    badge
                } else {
                    badge
                    scoreText
                }
            }
            
            Text(team.shortName)
                .font(.caption)
                .foregroundStyle(isHighlighted ? .orange : .primary)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
    }
    
    private var badge: some View {
        AsyncImage(url: URL(string: team.badgeURL ?? "")) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            Circle()
                .fill(.gray.opacity(0.3))
        }
        .frame(width: 32, height: 32)
        .opacity(isWinner ? 1.0 : 0.6)
    }
    
    private var scoreText: some View {
        Text("\(score ?? 0)")
            .font(.title2)
            .fontWeight(isWinner ? .bold : .regular)
            .foregroundStyle(isWinner ? .primary : .secondary)
    }
}

// MARK: - Team Badge

struct TeamBadge: View {
    let team: Team
    var isHighlighted: Bool = false
    var size: CGFloat = 36
    
    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: URL(string: team.badgeURL ?? "")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
            }
            .frame(width: size, height: size)
            
            Text(team.shortName)
                .font(.subheadline)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundStyle(isHighlighted ? .orange : .primary)
        }
    }
}

// MARK: - Widget Game Card

struct WidgetGameCard: View {
    let game: Game
    let showScore: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(game.homeTeam.shortName)
                        .font(.headline)
                    Text(game.awayTeam.shortName)
                        .font(.headline)
                }
                
                Spacer()
                
                if showScore, let home = game.homeScore, let away = game.awayScore {
                    VStack(alignment: .trailing) {
                        Text("\(home)")
                            .font(.headline)
                            .fontWeight(game.winner?.id == game.homeTeam.id ? .bold : .regular)
                        Text("\(away)")
                            .font(.headline)
                            .fontWeight(game.winner?.id == game.awayTeam.id ? .bold : .regular)
                    }
                } else {
                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Game Row") {
    List {
        GameRow(game: .preview)
        GameRow(game: .preview, highlightTeamID: "154048")
    }
}

#Preview("Result Row") {
    List {
        ResultRow(game: .previewCompleted)
        ResultRow(game: .previewCompleted, highlightTeamID: "154048")
    }
}

// MARK: - Preview Helpers

extension Game {
    static var preview: Game {
        Game(
            id: "1",
            homeTeam: Team(id: "154048", name: "Breeze BC", badgeURL: nil),
            awayTeam: Team(id: "154049", name: "Hive BC", badgeURL: nil),
            homeScore: nil,
            awayScore: nil,
            date: Date().addingTimeInterval(86400),
            status: .scheduled,
            thumbnailURL: nil
        )
    }
    
    static var previewCompleted: Game {
        Game(
            id: "2",
            homeTeam: Team(id: "154048", name: "Breeze BC", badgeURL: nil),
            awayTeam: Team(id: "154049", name: "Hive BC", badgeURL: nil),
            homeScore: 78,
            awayScore: 65,
            date: Date().addingTimeInterval(-86400),
            status: .completed,
            thumbnailURL: nil
        )
    }
}
