import Foundation
import Network

@MainActor
final class GlassesServer {

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private(set) var clientCount = 0

    func start() {
        guard listener == nil else { return }
        do { listener = try NWListener(using: .tcp, on: 8093) } catch { return }
        listener?.stateUpdateHandler = { [weak self] state in
            if case .failed = state { Task { @MainActor [weak self] in self?.restart() } }
        }
        listener?.newConnectionHandler = { [weak self] conn in
            Task { @MainActor [weak self] in self?.accept(conn) }
        }
        listener?.start(queue: .main)
    }

    func stop() {
        listener?.cancel(); listener = nil
        connections.forEach { $0.cancel() }; connections.removeAll(); clientCount = 0
    }

    private func restart() {
        stop()
        Task { @MainActor in try? await Task.sleep(for: .seconds(3)); self.start() }
    }

    private func accept(_ conn: NWConnection) {
        conn.stateUpdateHandler = { [weak self, weak conn] state in
            guard let self, let conn else { return }
            Task { @MainActor [weak self] in
                switch state {
                case .ready:
                    self?.connections.append(conn)
                    self?.clientCount = self?.connections.count ?? 0
                case .failed, .cancelled:
                    self?.connections.removeAll { $0 === conn }
                    self?.clientCount = self?.connections.count ?? 0
                default: break
                }
            }
        }
        conn.start(queue: .main)
    }

    private func broadcast(_ text: String) {
        guard !connections.isEmpty else { return }
        let data = (text + "\n").data(using: .utf8)!
        connections.forEach { $0.send(content: data, completion: .contentProcessed { _ in }) }
    }

    func broadcastScores(games: [Game], format: GlassesFormat) {
        let text = formatScores(games: games, format: format)
        if let json = try? JSONSerialization.data(withJSONObject: ["type": "scores", "text": text, "count": games.count]),
           let str = String(data: json, encoding: .utf8) { broadcast(str) }
    }

    func broadcastAlert(text: String) {
        if let json = try? JSONSerialization.data(withJSONObject: ["type": "alert", "text": text]),
           let str = String(data: json, encoding: .utf8) { broadcast(str) }
    }

    private func formatScores(games: [Game], format: GlassesFormat) -> String {
        let live = games.filter { $0.status.isLive }
        let display = live.isEmpty ? games.prefix(4) : ArraySlice(live.prefix(4))

        switch format {
        case .compact:
            return display.map { $0.compactLine }.joined(separator: "  |  ")
        case .detailed:
            return display.map { g in
                let league = League.all.first { $0.id == g.leagueId }?.emoji ?? ""
                return "\(league) \(g.away.abbreviation) \(g.away.score) – \(g.home.abbreviation) \(g.home.score) [\(g.status.label)]"
            }.joined(separator: "\n")
        case .minimal:
            return display.map { "\($0.away.abbreviation) \($0.away.score)-\($0.home.score) \($0.home.abbreviation)" }
                .joined(separator: "  ")
        }
    }
}
