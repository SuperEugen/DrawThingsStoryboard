import SwiftUI

/// Lightweight placeholder item for UI prototyping.
/// Replace with real domain models once filesystem layer is built.
struct MockItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let status: String
    let variantCount: Int
}

enum MockItems {

    static func items(for section: AppSection?) -> [MockItem] {
        switch section {
        case .briefing:
            return [
                MockItem(id: "b-01", name: "Studio Config",      icon: "gearshape",          color: .indigo,  status: "Draft",    variantCount: 1),
                MockItem(id: "b-02", name: "Episode Config",     icon: "doc.badge.gearshape", color: .indigo,  status: "Draft",    variantCount: 1),
            ]
        case .casting:
            return [
                MockItem(id: "c-01", name: "Alex — Hero",        icon: "person.fill",         color: .blue,    status: "Approved", variantCount: 3),
                MockItem(id: "c-02", name: "Sam — Sidekick",     icon: "person.fill",         color: .cyan,    status: "Draft",    variantCount: 2),
                MockItem(id: "c-03", name: "Jordan — Villain",   icon: "person.fill",         color: .red,     status: "Draft",    variantCount: 1),
                MockItem(id: "c-04", name: "Rooftop — Night",    icon: "building.2",          color: .purple,  status: "Approved", variantCount: 4),
                MockItem(id: "c-05", name: "Office — Day",       icon: "building.2",          color: .orange,  status: "Draft",    variantCount: 2),
            ]
        case .writing:
            return [
                MockItem(id: "w-01", name: "Act 1 — Setup",      icon: "doc.text",            color: .green,   status: "Draft",    variantCount: 1),
                MockItem(id: "w-02", name: "Act 2 — Conflict",   icon: "doc.text",            color: .green,   status: "Draft",    variantCount: 1),
                MockItem(id: "w-03", name: "Act 3 — Resolution", icon: "doc.text",            color: .green,   status: "Draft",    variantCount: 1),
            ]
        case .production:
            return [
                MockItem(id: "p-01", name: "Seq 01 — Sc 01",     icon: "photo",               color: .yellow,  status: "Draft",    variantCount: 2),
                MockItem(id: "p-02", name: "Seq 01 — Sc 02",     icon: "photo",               color: .yellow,  status: "Approved", variantCount: 1),
                MockItem(id: "p-03", name: "Seq 01 — Sc 03",     icon: "photo",               color: .yellow,  status: "Draft",    variantCount: 3),
                MockItem(id: "p-04", name: "Seq 02 — Sc 01",     icon: "photo",               color: .orange,  status: "Draft",    variantCount: 1),
            ]
        case .library:
            return [
                MockItem(id: "l-01", name: "studio_main",        icon: "building.columns",    color: .teal,    status: "Active",   variantCount: 12),
                MockItem(id: "l-02", name: "customer_acme",      icon: "person.text.rectangle",color: .teal,   status: "Active",   variantCount: 6),
            ]
        case .none:
            return []
        }
    }
}
