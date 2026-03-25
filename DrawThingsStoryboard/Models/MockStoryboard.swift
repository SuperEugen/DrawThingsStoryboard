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

// MockPanel, MockScene, MockSequence, MockAct are defined in MockItem.swift
