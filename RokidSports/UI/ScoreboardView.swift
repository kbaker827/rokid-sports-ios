import SwiftUI

struct ScoreboardView: View {
    @EnvironmentObject private var vm: SportsViewModel
    @EnvironmentObject private var settings: SettingsStore
    @State private var selectedLeague: String = "all"

    private var leagueTabs: [League] {
        [League(id: "all", name: "All", shortName: "All", sport: "", slug: "", emoji: "🏆")] +
        settings.enabledLeagues
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // League tab strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(leagueTabs) { league in
                            Button {
                                withAnimation { selectedLeague = league.id }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(league.emoji)
                                    Text(league.shortName)
                                        .font(.footnote.weight(.semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedLeague == league.id ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundStyle(selectedLeague == league.id ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // Games list
                let games: [Game] = selectedLeague == "all"
                    ? vm.filteredGames
                    : (vm.gamesByLeague[selectedLeague] ?? []).filter { g in
                        if !settings.showScheduled, case .scheduled = g.status { return false }
                        return true
                    }

                if vm.isRefreshing && games.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if games.isEmpty {
                    ContentUnavailableView(
                        "No Games",
                        systemImage: "sportscourt",
                        description: Text("No games right now. Enable more leagues in Settings.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(games) { game in
                        GameRow(game: game)
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("Live Scores")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Glasses / live indicator
                    HStack(spacing: 4) {
                        Circle().fill(vm.glassesClientCount > 0 ? Color.green : Color.gray).frame(width: 8, height: 8)
                        Text(":8093").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        if vm.isRefreshing { ProgressView().controlSize(.small) }
                        if let d = vm.lastUpdated {
                            Text(d, style: .relative).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Button { Task { await vm.refresh() } } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Game Row

struct GameRow: View {
    let game: Game

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(statusBadge)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
                Spacer()
                if let venue = game.venue {
                    Text(venue)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 0) {
                teamStack(game.away)
                Text("–").font(.title3).foregroundStyle(.secondary).frame(width: 30)
                teamStack(game.home)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(game.isAlerting ? Color.green.opacity(0.05) : Color.clear)
    }

    @ViewBuilder
    private func teamStack(_ t: TeamScore) -> some View {
        HStack {
            if !t.isHome {
                Text(t.abbreviation)
                    .font(.headline.weight(t.isWinner ? .bold : .regular))
                    .foregroundStyle(t.isWinner ? .primary : .secondary)
                Spacer()
                Text(t.score)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(t.isWinner ? .primary : .secondary)
            } else {
                Text(t.score)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(t.isWinner ? .primary : .secondary)
                Spacer()
                Text(t.abbreviation)
                    .font(.headline.weight(t.isWinner ? .bold : .regular))
                    .foregroundStyle(t.isWinner ? .primary : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statusBadge: String {
        switch game.status {
        case .inProgress(let d): return d
        case .final_:            return "Final"
        case .scheduled(let d):
            let f = DateFormatter(); f.timeStyle = .short
            return f.string(from: d)
        case .postponed:  return "PPD"
        case .cancelled:  return "Cancelled"
        case .suspended:  return "Suspended"
        }
    }

    private var statusColor: Color {
        switch game.status {
        case .inProgress: return .green
        case .final_:     return .secondary
        case .postponed, .cancelled: return .orange
        default:          return .blue
        }
    }
}

// MARK: - Alerts

struct AlertsFeed: View {
    let alerts: [String]

    var body: some View {
        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(alerts.prefix(3), id: \.self) { a in
                    HStack {
                        Image(systemName: "bell.fill").font(.caption).foregroundStyle(.orange)
                        Text(a).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    ScoreboardView()
        .environmentObject(SportsViewModel())
        .environmentObject(SettingsStore.shared)
}
