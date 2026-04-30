import Foundation
import Combine

@MainActor
final class SportsViewModel: ObservableObject {

    @Published private(set) var gamesByLeague: [String: [Game]] = [:]
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var error: String?
    @Published private(set) var recentAlerts: [String] = []
    @Published private(set) var glassesClientCount = 0

    let settings = SettingsStore.shared
    private let api = SportsAPIClient()
    private let glassesServer = GlassesServer()

    private var refreshTimer: Timer?
    // Score snapshot for change detection: "gameId" -> "AWAY_SCORE-HOME_SCORE"
    private var prevScores: [String: String] = [:]

    init() {
        glassesServer.start()
        Task { await refresh() }
        startTimer()
    }

    deinit { refreshTimer?.invalidate() }

    // MARK: - All games flattened

    var allGames: [Game] {
        gamesByLeague.values.flatMap { $0 }
            .sorted { a, b in
                // Live first, then scheduled, then final
                let rank: (Game) -> Int = { g in
                    switch g.status {
                    case .inProgress: return 0
                    case .scheduled:  return 1
                    default:          return 2
                    }
                }
                return rank(a) < rank(b)
            }
    }

    var liveGames: [Game] { allGames.filter { $0.status.isLive } }

    var filteredGames: [Game] {
        var games = allGames
        if settings.favoritesOnly && !settings.favoriteTeams.isEmpty {
            let favAbbrs = Set(settings.favoriteTeams.map { $0.abbreviation })
            games = games.filter {
                favAbbrs.contains($0.home.abbreviation) || favAbbrs.contains($0.away.abbreviation)
            }
        }
        if !settings.showScheduled {
            games = games.filter { g in
                if case .scheduled = g.status { return false }
                return true
            }
        }
        return games
    }

    // MARK: - Refresh

    func refresh() async {
        isRefreshing = true
        error = nil

        var newGames: [String: [Game]] = [:]
        var errors: [String] = []

        await withTaskGroup(of: (String, [Game]?).self) { group in
            for league in settings.enabledLeagues {
                group.addTask { [weak self] in
                    guard let self else { return (league.id, nil) }
                    do {
                        let games = try await self.api.fetchGames(league: league)
                        return (league.id, games)
                    } catch {
                        return (league.id, nil)
                    }
                }
            }
            for await (leagueId, games) in group {
                if let games { newGames[leagueId] = games }
                else { errors.append(leagueId) }
            }
        }

        // Detect score changes
        if settings.alertScoreChanges {
            checkScoreChanges(newGames: newGames)
        }

        gamesByLeague = newGames
        lastUpdated   = Date()
        isRefreshing  = false

        if !errors.isEmpty { error = "Failed to load: \(errors.joined(separator: ", "))" }

        glassesClientCount = glassesServer.clientCount
        glassesServer.broadcastScores(games: filteredGames, format: settings.glassesFormat)
    }

    // MARK: - Score change detection

    private func checkScoreChanges(newGames: [String: [Game]]) {
        for (_, games) in newGames {
            for game in games {
                guard game.status.isLive else { continue }
                let key     = game.id
                let current = "\(game.away.score)-\(game.home.score)"
                let prev    = prevScores[key]

                if let prev, prev != current {
                    let league = League.all.first { $0.id == game.leagueId }
                    let emoji  = league?.emoji ?? "🏆"
                    let text   = "\(emoji) \(game.away.abbreviation) \(game.away.score) – \(game.home.abbreviation) \(game.home.score) (\(game.status.label))"

                    // Only alert for favorite teams if favoritesOnly, else alert for all
                    let favAbbrs = Set(settings.favoriteTeams.map { $0.abbreviation })
                    let isFav = favAbbrs.contains(game.home.abbreviation) || favAbbrs.contains(game.away.abbreviation)

                    if settings.favoriteTeams.isEmpty || isFav {
                        postAlert(text)
                    }
                }
                prevScores[key] = current
            }
        }
    }

    private func postAlert(_ text: String) {
        recentAlerts.insert(text, at: 0)
        if recentAlerts.count > 30 { recentAlerts.removeLast() }
        glassesServer.broadcastAlert(text: text)
    }

    // MARK: - Timer

    private func startTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }

    func restartTimer() {
        startTimer()
    }

    // MARK: - Helpers

    func games(for leagueId: String) -> [Game] {
        var g = gamesByLeague[leagueId] ?? []
        if !settings.showScheduled { g = g.filter { if case .scheduled = $0.status { return false }; return true } }
        return g
    }

    func league(for id: String) -> League? {
        League.all.first { $0.id == id }
    }
}
