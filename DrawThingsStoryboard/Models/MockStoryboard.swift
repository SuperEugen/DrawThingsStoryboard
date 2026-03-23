import SwiftUI

// MARK: - Storyboard level

/// Which level of the storyboard hierarchy the user is viewing.
enum StoryboardLevel: String, Hashable {
    case act
    case sequence
    case scene
    case panel

    var label: String {
        switch self {
        case .act:      return "Act"
        case .sequence: return "Sequence"
        case .scene:    return "Scene"
        case .panel:    return "Panel"
        }
    }

    var icon: String {
        switch self {
        case .act:      return "theatermask.and.paintbrush"
        case .sequence: return "arrow.triangle.branch"
        case .scene:    return "rectangle.on.rectangle"
        case .panel:    return "photo"
        }
    }

    var color: Color {
        switch self {
        case .act:      return .purple
        case .sequence: return .orange
        case .scene:    return .teal
        case .panel:    return .blue
        }
    }
}

// MARK: - Selection

/// Identifies which storyboard element is currently selected.
enum StoryboardSelection: Hashable {
    case act(String)
    case sequence(String)
    case scene(String)
    case panel(String)
}

// MARK: - Mock storyboard data
// MockPanel, MockScene, MockSequence, MockAct are defined in MockItem.swift

extension MockData {

    static let sampleActs: [MockAct] = [
        MockAct(
            id: "act-01",
            name: "Setup",
            description: "Introduce the characters and the world.",
            sequences: [
                MockSequence(
                    id: "seq-01",
                    name: "Opening",
                    description: "The opening sequence establishes the city and tone.",
                    scenes: [
                        MockScene(
                            id: "scn-01",
                            name: "City Establishing",
                            description: "Wide shot of the city at night, rain-soaked streets.",
                            panels: [
                                MockPanel(id: "pnl-01", name: "Skyline Wide", description: "Wide city skyline.", smallPanelAvailable: true, largePanelAvailable: true),
                                MockPanel(id: "pnl-02", name: "Street Level", description: "Rain on the street.", smallPanelAvailable: true),
                            ]
                        ),
                        MockScene(
                            id: "scn-02",
                            name: "Intro",
                            description: "Alex walks through the rain.",
                            panels: [
                                MockPanel(id: "pnl-03", name: "Alex Walking", description: "Alex in a trenchcoat."),
                            ]
                        ),
                    ]
                ),
                MockSequence(
                    id: "seq-02",
                    name: "Backstory",
                    description: "Flashback revealing Alex's motivation and past.",
                    scenes: [
                        MockScene(
                            id: "scn-05",
                            name: "Childhood Home",
                            description: "Young Alex in a sunlit living room, family photos on the wall.",
                            panels: [
                                MockPanel(id: "pnl-07", name: "Family Portrait", description: "Close-up of a framed family photo.", smallPanelAvailable: true),
                                MockPanel(id: "pnl-08", name: "Window Light", description: "Sunlight streaming through curtains.", smallPanelAvailable: true),
                            ]
                        ),
                        MockScene(
                            id: "scn-06",
                            name: "The Promise",
                            description: "Alex makes a promise at a graveside.",
                            panels: [
                                MockPanel(id: "pnl-09", name: "Gravestone", description: "Rain on a gravestone."),
                            ]
                        ),
                    ]
                ),
            ]
        ),
        MockAct(
            id: "act-02",
            name: "Conflict",
            description: "The tension escalates as the antagonist is revealed.",
            sequences: [
                MockSequence(
                    id: "seq-03",
                    name: "Discovery",
                    description: "Alex discovers the conspiracy at the office.",
                    scenes: [
                        MockScene(
                            id: "scn-07",
                            name: "Office Break-In",
                            description: "Alex sneaks into the corporate office after hours.",
                            panels: [
                                MockPanel(id: "pnl-10", name: "Hallway Shadows", description: "Alex creeping through a dark hallway.", smallPanelAvailable: true),
                                MockPanel(id: "pnl-11", name: "Computer Screen", description: "Incriminating data on a monitor."),
                            ]
                        ),
                        MockScene(
                            id: "scn-08",
                            name: "Caught",
                            description: "Security catches Alex red-handed.",
                            panels: [
                                MockPanel(id: "pnl-12", name: "Flashlight Beam", description: "A flashlight beam sweeps across the room."),
                                MockPanel(id: "pnl-13", name: "Alarm", description: "Red alarm lights flash."),
                            ]
                        ),
                    ]
                ),
                MockSequence(
                    id: "seq-04",
                    name: "Chase",
                    description: "A rooftop chase through the city.",
                    scenes: [
                        MockScene(
                            id: "scn-03",
                            name: "Rooftop",
                            description: "Alex chases Jordan across rooftops.",
                            panels: [
                                MockPanel(id: "pnl-04", name: "Leap", description: "Alex leaps between buildings.", smallPanelAvailable: true, largePanelAvailable: true),
                                MockPanel(id: "pnl-05", name: "Confrontation", description: "Face to face on the ledge."),
                            ]
                        ),
                        MockScene(
                            id: "scn-09",
                            name: "Alley Escape",
                            description: "Alex escapes through narrow alleys.",
                            panels: [
                                MockPanel(id: "pnl-14", name: "Dumpster Hide", description: "Alex hides behind a dumpster."),
                                MockPanel(id: "pnl-15", name: "Fence Jump", description: "Alex vaults over a chain-link fence.", smallPanelAvailable: true),
                            ]
                        ),
                    ]
                ),
            ]
        ),
        MockAct(
            id: "act-03",
            name: "Resolution",
            description: "The conflict resolves and a new status quo emerges.",
            sequences: [
                MockSequence(
                    id: "seq-07",
                    name: "Finale",
                    description: "The final confrontation and aftermath.",
                    scenes: [
                        MockScene(
                            id: "scn-04",
                            name: "Showdown",
                            description: "The climactic showdown in the underground station.",
                            panels: [
                                MockPanel(id: "pnl-06", name: "Standoff", description: "Tense standoff under flickering lights."),
                                MockPanel(id: "pnl-21", name: "Final Blow", description: "The decisive moment of the fight."),
                            ]
                        ),
                        MockScene(
                            id: "scn-12",
                            name: "Aftermath",
                            description: "The dust settles, dawn breaks over the city.",
                            panels: [
                                MockPanel(id: "pnl-22", name: "Sunrise", description: "Golden sunrise over the city skyline.", smallPanelAvailable: true),
                                MockPanel(id: "pnl-23", name: "Alex Walks Away", description: "Alex walks into the morning light."),
                            ]
                        ),
                    ]
                ),
            ]
        ),
    ]
}
