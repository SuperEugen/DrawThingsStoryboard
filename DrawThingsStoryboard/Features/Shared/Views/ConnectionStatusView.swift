import SwiftUI
import Network

// MARK: - Connection Status View (#15)

/// Small toolbar indicator showing Draw Things gRPC server reachability.
/// Checks connectivity every 30 seconds via a TCP connection test.
struct ConnectionStatusView: View {
    let address: String
    let port: Int

    @State private var status: ConnectionState = .unknown
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    enum ConnectionState {
        case unknown, checking, connected, disconnected

        var color: Color {
            switch self {
            case .unknown: return .gray
            case .checking: return .yellow
            case .connected: return .green
            case .disconnected: return .red
            }
        }

        var icon: String {
            switch self {
            case .unknown: return "circle.dotted"
            case .checking: return "arrow.triangle.2.circlepath"
            case .connected: return "circle.fill"
            case .disconnected: return "circle.slash"
            }
        }

        var label: String {
            switch self {
            case .unknown: return "Not checked"
            case .checking: return "Checking\u{2026}"
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 8))
                .foregroundStyle(status.color)
            Text("DT").font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(.ultraThinMaterial, in: Capsule())
        .help("Draw Things: \(status.label) (\(address):\(port))")
        .onTapGesture { checkConnection() }
        .onAppear { checkConnection() }
        .onReceive(timer) { _ in checkConnection() }
        .onChange(of: address) { _, _ in checkConnection() }
        .onChange(of: port) { _, _ in checkConnection() }
    }

    private func checkConnection() {
        status = .checking
        let host = NWEndpoint.Host(address)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(clamping: port))
        let connection = NWConnection(host: host, port: nwPort, using: .tcp)

        connection.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.status = .connected
                    connection.cancel()
                case .failed, .cancelled:
                    if self.status == .checking {
                        self.status = .disconnected
                    }
                case .waiting:
                    self.status = .disconnected
                    connection.cancel()
                default:
                    break
                }
            }
        }

        connection.start(queue: .global(qos: .utility))

        // Timeout after 3 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if connection.state != .ready {
                connection.cancel()
                DispatchQueue.main.async {
                    if self.status == .checking {
                        self.status = .disconnected
                    }
                }
            }
        }
    }
}
