import SwiftUI

struct GlassesPreviewView: View {
    @EnvironmentObject private var vm: SportsViewModel
    @EnvironmentObject private var settings: SettingsStore

    private var previewLines: [String] {
        let games = vm.filteredGames
        let live = games.filter { $0.status.isLive }
        let display = live.isEmpty ? Array(games.prefix(4)) : Array(live.prefix(4))

        switch settings.glassesFormat {
        case .compact:
            return [display.map { $0.compactLine }.joined(separator: "  |  ")]
        case .detailed:
            return display.map { g in
                let emoji = League.all.first { $0.id == g.leagueId }?.emoji ?? "🏆"
                return "\(emoji) \(g.away.abbreviation) \(g.away.score) – \(g.home.abbreviation) \(g.home.score) [\(g.status.label)]"
            }
        case .minimal:
            return [display.map { "\($0.away.abbreviation) \($0.away.score)-\($0.home.score) \($0.home.abbreviation)" }.joined(separator: "  ")]
        }
    }

    private var rawJSON: String {
        let dict: [String: Any] = [
            "type":  "scores",
            "text":  previewLines.joined(separator: "\n"),
            "count": vm.filteredGames.count
        ]
        guard let d = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let s = String(data: d, encoding: .utf8) else { return "{}" }
        return s
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Format", selection: $settings.glassesFormat) {
                        ForEach(GlassesFormat.allCases) { f in Text(f.displayName).tag(f) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Glasses mockup
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10).fill(Color.black)
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(previewLines.isEmpty ? ["No games"] : previewLines, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.green)
                                    .lineLimit(2)
                            }
                        }
                        .padding(12)
                    }
                    .aspectRatio(16/4, contentMode: .fit)
                    .padding(.horizontal)

                    HStack(spacing: 6) {
                        Circle().fill(vm.glassesClientCount > 0 ? Color.green : Color.gray).frame(width: 8, height: 8)
                        Text("TCP :8093  —  \(vm.glassesClientCount) client(s) connected")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    // Live count
                    HStack {
                        Label("\(vm.liveGames.count) live games", systemImage: "dot.radiowaves.left.and.right")
                            .font(.caption).foregroundStyle(.green)
                        Spacer()
                        Label("\(vm.allGames.count) total", systemImage: "sportscourt")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    GroupBox("Raw JSON") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(rawJSON)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(4)
                        }
                    }
                    .padding(.horizontal)

                    // Recent alerts
                    if !vm.recentAlerts.isEmpty {
                        GroupBox("Recent Score Alerts") {
                            ForEach(vm.recentAlerts.prefix(5), id: \.self) { a in
                                HStack {
                                    Image(systemName: "bell.fill").font(.caption2).foregroundStyle(.orange)
                                    Text(a).font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 1)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Glasses Preview")
        }
    }
}
