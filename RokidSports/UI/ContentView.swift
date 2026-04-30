import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SportsViewModel()

    var body: some View {
        TabView {
            ScoreboardView()
                .tabItem { Label("Scores", systemImage: "sportscourt.fill") }
            GlassesPreviewView()
                .tabItem { Label("Glasses", systemImage: "eyeglasses") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .environmentObject(vm)
        .environmentObject(SettingsStore.shared)
    }
}
