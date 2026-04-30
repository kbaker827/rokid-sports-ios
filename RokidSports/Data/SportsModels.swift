import Foundation

// MARK: - League

struct League: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let shortName: String
    let sport: String       // "football", "basketball", "baseball", "hockey", "soccer"
    let slug: String        // "nfl", "nba", etc.
    let emoji: String

    var espnURL: String {
        "https://site.api.espn.com/apis/site/v2/sports/\(sport)/\(slug)/scoreboard"
    }

    static let all: [League] = [
        League(id: "nfl",   name: "NFL",              shortName: "NFL",  sport: "football",   slug: "nfl",                          emoji: "🏈"),
        League(id: "nba",   name: "NBA",              shortName: "NBA",  sport: "basketball", slug: "nba",                          emoji: "🏀"),
        League(id: "mlb",   name: "MLB",              shortName: "MLB",  sport: "baseball",   slug: "mlb",                          emoji: "⚾"),
        League(id: "nhl",   name: "NHL",              shortName: "NHL",  sport: "hockey",     slug: "nhl",                          emoji: "🏒"),
        League(id: "ncaaf", name: "College Football", shortName: "NCAAF",sport: "football",   slug: "college-football",             emoji: "🏈"),
        League(id: "ncaab", name: "College Basketball",shortName:"NCAAB",sport: "basketball", slug: "mens-college-basketball",      emoji: "🏀"),
        League(id: "mls",   name: "MLS",              shortName: "MLS",  sport: "soccer",     slug: "usa.1",                        emoji: "⚽"),
        League(id: "epl",   name: "Premier League",   shortName: "EPL",  sport: "soccer",     slug: "eng.1",                        emoji: "⚽"),
        League(id: "wnba",  name: "WNBA",             shortName: "WNBA", sport: "basketball", slug: "wnba",                         emoji: "🏀"),
        League(id: "cfb",   name: "CFL",              shortName: "CFL",  sport: "football",   slug: "canadian-football",            emoji: "🏈"),
    ]
}

// MARK: - Game status

enum GameStatus: Equatable {
    case scheduled(Date)
    case inProgress(detail: String)
    case final_
    case postponed
    case cancelled
    case suspended

    var label: String {
        switch self {
        case .scheduled(let d):
            let f = DateFormatter()
            f.timeStyle = .short
            return f.string(from: d)
        case .inProgress(let detail): return detail
        case .final_:      return "Final"
        case .postponed:   return "Postponed"
        case .cancelled:   return "Cancelled"
        case .suspended:   return "Suspended"
        }
    }

    var isLive: Bool {
        if case .inProgress = self { return true }
        return false
    }

    var isFinal: Bool { self == .final_ }
}

// MARK: - Team score

struct TeamScore: Equatable {
    let name: String
    let abbreviation: String
    let score: String
    let isWinner: Bool
    let isHome: Bool
}

// MARK: - Game

struct Game: Identifiable, Equatable {
    let id: String
    let leagueId: String
    let home: TeamScore
    let away: TeamScore
    let status: GameStatus
    let venue: String?

    var scoreDisplay: String {
        "\(away.abbreviation) \(away.score)  \(home.abbreviation) \(home.score)"
    }

    var compactLine: String {
        switch status {
        case .scheduled(let d):
            let f = DateFormatter(); f.timeStyle = .short
            return "\(away.abbreviation) vs \(home.abbreviation) \(f.string(from: d))"
        default:
            return "\(away.abbreviation) \(away.score) – \(home.abbreviation) \(home.score) (\(status.label))"
        }
    }

    var isAlerting: Bool { status.isLive }
}

// MARK: - ESPN API response models

struct ESPNScoreboard: Codable {
    let events: [ESPNEvent]?
}

struct ESPNEvent: Codable {
    let id: String
    let name: String
    let competitions: [ESPNCompetition]?
    let status: ESPNStatus?
}

struct ESPNStatus: Codable {
    let type: ESPNStatusType?
}

struct ESPNStatusType: Codable {
    let name: String
    let shortDetail: String?
    let description: String?
    let completed: Bool?
}

struct ESPNCompetition: Codable {
    let competitors: [ESPNCompetitor]?
    let venue: ESPNVenue?
    let date: String?
}

struct ESPNCompetitor: Codable {
    let team: ESPNTeam?
    let score: String?
    let homeAway: String?
    let winner: Bool?
}

struct ESPNTeam: Codable {
    let abbreviation: String?
    let displayName: String?
    let shortDisplayName: String?
}

struct ESPNVenue: Codable {
    let fullName: String?
}

// MARK: - Display format

enum GlassesFormat: String, CaseIterable, Identifiable {
    case compact, detailed, minimal
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Favorite team

struct FavoriteTeam: Codable, Identifiable, Equatable {
    var id: String { abbreviation }
    let abbreviation: String
    let name: String
    let leagueId: String
}
