import Foundation
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Key {
        static let enabledLeagues   = "enabled_leagues"
        static let favoriteTeams    = "favorite_teams"
        static let glassesFormat    = "glasses_format"
        static let refreshInterval  = "refresh_interval"
        static let showScheduled    = "show_scheduled"
        static let favoritesOnly    = "favorites_only"
        static let alertGoals       = "alert_goals"
    }

    @Published var enabledLeagueIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(enabledLeagueIds), forKey: Key.enabledLeagues)
        }
    }
    @Published var favoriteTeams: [FavoriteTeam] {
        didSet {
            if let d = try? JSONEncoder().encode(favoriteTeams) {
                UserDefaults.standard.set(d, forKey: Key.favoriteTeams)
            }
        }
    }
    @Published var glassesFormat: GlassesFormat {
        didSet { UserDefaults.standard.set(glassesFormat.rawValue, forKey: Key.glassesFormat) }
    }
    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: Key.refreshInterval) }
    }
    @Published var showScheduled: Bool {
        didSet { UserDefaults.standard.set(showScheduled, forKey: Key.showScheduled) }
    }
    @Published var favoritesOnly: Bool {
        didSet { UserDefaults.standard.set(favoritesOnly, forKey: Key.favoritesOnly) }
    }
    @Published var alertScoreChanges: Bool {
        didSet { UserDefaults.standard.set(alertScoreChanges, forKey: Key.alertGoals) }
    }

    var enabledLeagues: [League] {
        League.all.filter { enabledLeagueIds.contains($0.id) }
    }

    private init() {
        let ud = UserDefaults.standard
        if let arr = ud.array(forKey: Key.enabledLeagues) as? [String] {
            enabledLeagueIds = Set(arr)
        } else {
            enabledLeagueIds = ["nfl", "nba", "mlb", "nhl"]
        }
        if let d = ud.data(forKey: Key.favoriteTeams),
           let t = try? JSONDecoder().decode([FavoriteTeam].self, from: d) {
            favoriteTeams = t
        } else {
            favoriteTeams = []
        }
        refreshInterval    = ud.object(forKey: Key.refreshInterval) as? Double ?? 30
        showScheduled      = ud.object(forKey: Key.showScheduled) as? Bool ?? false
        favoritesOnly      = ud.object(forKey: Key.favoritesOnly) as? Bool ?? false
        alertScoreChanges  = ud.object(forKey: Key.alertGoals) as? Bool ?? true
        if let raw = ud.string(forKey: Key.glassesFormat),
           let fmt = GlassesFormat(rawValue: raw) {
            glassesFormat = fmt
        } else {
            glassesFormat = .compact
        }
    }

    func toggleLeague(_ id: String) {
        if enabledLeagueIds.contains(id) { enabledLeagueIds.remove(id) }
        else { enabledLeagueIds.insert(id) }
    }

    func addFavorite(_ team: FavoriteTeam) {
        guard !favoriteTeams.contains(where: { $0.id == team.id }) else { return }
        favoriteTeams.append(team)
    }

    func removeFavorite(_ abbreviation: String) {
        favoriteTeams.removeAll { $0.abbreviation == abbreviation }
    }

    func isFavorite(_ abbreviation: String) -> Bool {
        favoriteTeams.contains { $0.abbreviation == abbreviation }
    }
}
