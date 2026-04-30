import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: SportsViewModel
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Leagues") {
                    ForEach(League.all) { league in
                        HStack {
                            Text(league.emoji)
                            Text(league.name)
                            Spacer()
                            if settings.enabledLeagueIds.contains(league.id) {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { settings.toggleLeague(league.id) }
                    }
                }

                Section("Glasses Display") {
                    Picker("Format", selection: $settings.glassesFormat) {
                        ForEach(GlassesFormat.allCases) { f in Text(f.displayName).tag(f) }
                    }
                    LabeledContent("TCP port", value: "8093").foregroundStyle(.secondary)
                }

                Section("Refresh") {
                    HStack {
                        Text("Interval")
                        Spacer()
                        Text("\(Int(settings.refreshInterval))s").foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.refreshInterval, in: 10...120, step: 10) {
                        Text("Interval")
                    } minimumValueLabel: { Text("10s").font(.caption) }
                      maximumValueLabel: { Text("120s").font(.caption) }
                    .onChange(of: settings.refreshInterval) { _, _ in vm.restartTimer() }
                }

                Section("Filters") {
                    Toggle("Show scheduled games",   isOn: $settings.showScheduled)
                    Toggle("Favorites only",          isOn: $settings.favoritesOnly)
                    Toggle("Alert on score changes",  isOn: $settings.alertScoreChanges)
                }

                Section("Favorite Teams") {
                    if settings.favoriteTeams.isEmpty {
                        Text("No favorites yet. Add team abbreviations below.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        ForEach(settings.favoriteTeams) { team in
                            HStack {
                                Text(team.abbreviation).bold()
                                Text(team.name).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { settings.favoriteTeams.remove(at: $0) }
                        }
                    }
                    NavigationLink("Add favorite team") { AddFavoriteView() }
                }

                Section("About") {
                    LabeledContent("Data source", value: "ESPN (free, no key)")
                    LabeledContent("Version",     value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .toolbar { EditButton() }
        }
    }
}

struct AddFavoriteView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var abbreviation = ""
    @State private var name         = ""
    @State private var leagueId     = "nfl"

    var body: some View {
        Form {
            Section {
                TextField("Abbreviation (e.g. NYG)", text: $abbreviation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                TextField("Full name (e.g. New York Giants)", text: $name)
                Picker("League", selection: $leagueId) {
                    ForEach(League.all) { l in Text("\(l.emoji) \(l.name)").tag(l.id) }
                }
            }
            Button("Add") {
                guard !abbreviation.isEmpty, !name.isEmpty else { return }
                settings.addFavorite(FavoriteTeam(abbreviation: abbreviation.uppercased(),
                                                   name: name, leagueId: leagueId))
                dismiss()
            }
            .disabled(abbreviation.isEmpty || name.isEmpty)
        }
        .navigationTitle("Add Favorite")
    }
}
