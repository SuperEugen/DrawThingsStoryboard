import Foundation

/// #59: Pushover notification service.
/// Sends push notifications via the Pushover API (https://pushover.net).
/// Fire-and-forget — errors are logged but don’t interrupt the queue.

enum PushoverService {

    private static let endpoint = URL(string: "https://api.pushover.net/1/messages.json")!

    /// Send a Pushover notification. Requires valid token + user in config.
    static func send(
        title: String,
        message: String,
        config: AppConfig
    ) {
        guard !config.pushoverToken.isEmpty, !config.pushoverUser.isEmpty else {
            print("[Pushover] Skipped \u{2014} token or user not configured")
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "token": config.pushoverToken,
            "user": config.pushoverUser,
            "title": title,
            "message": message
        ]
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("[Pushover] Error: \(error.localizedDescription)")
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                print("[Pushover] HTTP \(http.statusCode): \(body)")
            } else {
                print("[Pushover] Notification sent: \(title)")
            }
        }.resume()
    }
}
