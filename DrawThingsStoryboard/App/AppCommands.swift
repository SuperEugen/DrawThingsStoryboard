import SwiftUI

/// Top-level menu bar commands.
struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            // File menu entries added per feature
        }
    }
}
