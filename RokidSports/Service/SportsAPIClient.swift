import Foundation

// MARK: - Sports API Client (ESPN free API — no key required)

actor SportsAPIClient {

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 10
        cfg.timeoutIntervalForResource = 20
        cfg.requestCachePolicy         = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Fetch scores for a league

    func fetchGames(league: League) async throws -> [Game] {
        let url = URL(string: league.espnURL)!
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw SportsError.httpError(http.statusCode)
        }

        let scoreboard = try decoder.decode(ESPNScoreboard.self, from: data)
        return (scoreboard.events ?? []).compactMap { parseGame($0, leagueId: league.id) }
    }

    // MARK: - Parse ESPN event → Game

    private func parseGame(_ event: ESPNEvent, leagueId: String) -> Game? {
        guard let competition = event.competitions?.first,
              let competitors = competition.competitors,
              competitors.count >= 2 else { return nil }

        let home = competitors.first { $0.homeAway == "home" }
        let away = competitors.first { $0.homeAway == "away" }

        guard let h = home, let a = away else { return nil }

        let homeTeam = TeamScore(
            name:         h.team?.displayName ?? "Home",
            abbreviation: h.team?.abbreviation ?? "HM",
            score:        h.score ?? "0",
            isWinner:     h.winner ?? false,
            isHome:       true
        )
        let awayTeam = TeamScore(
            name:         a.team?.displayName ?? "Away",
            abbreviation: a.team?.abbreviation ?? "AW",
            score:        a.score ?? "0",
            isWinner:     a.winner ?? false,
            isHome:       false
        )

        let status = parseStatus(event.status, competition: competition)

        return Game(
            id:       event.id,
            leagueId: leagueId,
            home:     homeTeam,
            away:     awayTeam,
            status:   status,
            venue:    competition.venue?.fullName
        )
    }

    private func parseStatus(_ status: ESPNStatus?, competition: ESPNCompetition) -> GameStatus {
        guard let typeName = status?.type?.name else {
            return parseScheduledDate(from: competition.date)
        }

        switch typeName {
        case "STATUS_SCHEDULED":
            return parseScheduledDate(from: competition.date)
        case "STATUS_IN_PROGRESS", "STATUS_HALFTIME":
            let detail = status?.type?.shortDetail ?? "Live"
            return .inProgress(detail: detail)
        case "STATUS_FINAL", "STATUS_FULL_TIME":
            return .final_
        case "STATUS_POSTPONED":
            return .postponed
        case "STATUS_CANCELLED":
            return .cancelled
        case "STATUS_SUSPENDED":
            return .suspended
        default:
            if typeName.contains("PROGRESS") { return .inProgress(detail: status?.type?.shortDetail ?? "Live") }
            if typeName.contains("FINAL")    { return .final_ }
            return parseScheduledDate(from: competition.date)
        }
    }

    private func parseScheduledDate(from str: String?) -> GameStatus {
        guard let str else { return .scheduled(Date()) }
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: str) ?? Date()
        return .scheduled(date)
    }
}

// MARK: - Errors

enum SportsError: LocalizedError {
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .httpError(let c): return "HTTP error \(c) from ESPN API."
        case .noData:           return "No data returned."
        }
    }
}
