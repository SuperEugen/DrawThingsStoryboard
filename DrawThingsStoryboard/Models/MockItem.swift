import Foundation
import SwiftUI

// MARK: - Variant

struct Variant: Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var prompt: String
    var imageName: String?
    var generatedImage: Data?
    var thumbnailColor: Color

    enum GenerationStatus {
        case pending, generating, complete, failed
    }
    var status: GenerationStatus = .pending
}

// MARK: - Look / Style template

enum LookStatus {
    case noExample
    case exampleAvailable
}

/// A visual style template. Describes HOW something looks (style prompt).
/// Model/steps/guidance are now in ModelConfig.
struct GenerationTemplate: Identifiable {
    let id: String
    var name: String
    var description: String       // style prompt appended to every generation
    var itemType: CastingItemType
    var lookStatus: LookStatus = .noExample
}

// MARK: - Casting

enum CastingItemType: String, CaseIterable {
    case character
    case location
}

enum CharacterGender: String, CaseIterable {
    case male, female, neutral
}

enum LocationSetting: String, CaseIterable {
    case interior, exterior, mixed
}

struct CastingItem: Identifiable, Equatable {
    let id: String
    var name: String
    var type: CastingItemType
    var description: String
    var prompt: String
    var gender: CharacterGender?
    var locationSetting: LocationSetting?
    var variants: [Variant]
}

// MARK: - Library tree structs

struct MockEpisode: Identifiable, Hashable {
    let id: String
    var name: String
    var characters: [String]   // IDs referencing studio.characters
    var locations:  [String]   // IDs referencing studio.locations
    var acts: [MockAct] = []
    var preferredLookID: String? = nil
}

struct MockCustomer: Identifiable, Hashable {
    let id: String
    var name: String
    var episodes: [MockEpisode]
    var preferredLookID: String? = nil
}

struct MockStudio: Identifiable, Hashable {
    let id: String
    var name: String
    var customers: [MockCustomer]
    var characters: [CastingItem]
    var locations:  [CastingItem]
    var preferredLookID: String? = nil
}

// MARK: - Generation Job types

enum GenerationSize: String, CaseIterable {
    case small = "Small (Variant)"
    case large = "Large (Final)"
}

enum GenerationJobType: String, CaseIterable, Identifiable {
    case generatePanel   = "Generate Panel"
    case generateExample = "Generate Example"
    case generateAsset   = "Generate Asset"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .generatePanel:   return "rectangle.3.group"
        case .generateExample: return "eye"
        case .generateAsset:   return "photo"
        }
    }

    var color: Color {
        switch self {
        case .generatePanel:   return .blue
        case .generateExample: return .purple
        case .generateAsset:   return .teal
        }
    }
}

struct GenerationJob: Identifiable {
    let id: String
    let itemName: String
    let itemType: CastingItemType
    let jobType: GenerationJobType
    let size: GenerationSize
    let lookName: String
    let queuedAt: Date
    let estimatedDuration: TimeInterval
    let itemIcon: String
    var itemGender: CharacterGender? = nil
    var itemLocationSetting: LocationSetting? = nil
    let seed: Int64
    let width: Int
    let height: Int
    let combinedPrompt: String
    var variantCount: Int = 0
    var attachedAssets: [JobAssetInfo] = []
}

struct JobAssetInfo: Identifiable {
    let id: String
    let name: String
    let type: CastingItemType
    let icon: String
    var gender: CharacterGender? = nil
    var locationSetting: LocationSetting? = nil
}

// MARK: - Size configuration keys

enum SizeConfigKeys {
    static let previewVariantWidth  = "dts.previewVariantWidth"
    static let previewVariantHeight = "dts.previewVariantHeight"
    static let finalWidth           = "dts.finalWidth"
    static let finalHeight          = "dts.finalHeight"
}

enum SizeConfigDefaults {
    static let previewVariantWidth  = 576
    static let previewVariantHeight = 320
    static let finalWidth           = 1920
    static let finalHeight          = 1080
}

// MARK: - Generic browser item

struct MockItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let thumbnailColor: Color
    let icon: String
}

// MARK: - Storyboard models

struct MockPanel: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var generatedImageData: Data? = nil
}

struct MockScene: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var panels: [MockPanel]
}

struct MockSequence: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var scenes: [MockScene]
}

struct MockAct: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var sequences: [MockSequence]
}

// MARK: - Mock data

struct MockData {
    static let defaultStudios: [MockStudio] = [
        MockStudio(
            id: "studio-1",
            name: "Alpha Studio",
            customers: [
                MockCustomer(
                    id: "customer-1",
                    name: "Acme Corp",
                    episodes: [
                        MockEpisode(id: "episode-1", name: "Pilot", characters: ["char-1"], locations: ["loc-1"]),
                        MockEpisode(id: "episode-2", name: "Episode 2", characters: ["char-1"], locations: ["loc-1"])
                    ]
                )
            ],
            characters: [
                CastingItem(id: "char-1", name: "The Hero", type: .character,
                            description: "Determined, mid-30s.", prompt: "Full-body character portrait, neutral background, consistent lighting.",
                            gender: .male, locationSetting: nil, variants: [])
            ],
            locations: [
                CastingItem(id: "loc-1", name: "City Street", type: .location,
                            description: "Rain-soaked streets.", prompt: "Urban environment, night scene, noir atmosphere.",
                            gender: nil, locationSetting: .exterior, variants: [])
            ]
        )
    ]

    static let defaultTemplates: [GenerationTemplate] = [
        GenerationTemplate(
            id: "tmpl-1",
            name: "Photorealistic",
            description: "cinematic lighting, photorealistic, 8k resolution, dramatic shadows, corporate thriller aesthetic, muted color palette, urban environments, night scenes, noir atmosphere, rain-soaked streets",
            itemType: .character
        ),
        GenerationTemplate(
            id: "tmpl-2",
            name: "Comic Style",
            description: "comic book style, bold outlines, flat colors, graphic novel aesthetic, high contrast",
            itemType: .character
        )
    ]

    static let sampleQueue: [GenerationJob] = [
        GenerationJob(
            id: "job-1",
            itemName: "The Hero",
            itemType: .character,
            jobType: .generateAsset,
            size: .small,
            lookName: "Photorealistic",
            queuedAt: Date(),
            estimatedDuration: 300,
            itemIcon: "person.fill",
            itemGender: .male,
            seed: Int64.random(in: 1...999_999),
            width: 576,
            height: 320,
            combinedPrompt: "cinematic lighting, photorealistic, 8k resolution, dramatic shadows, corporate thriller aesthetic, muted color palette, urban environments, night scenes, noir atmosphere, rain-soaked streets, Full-body character portrait, neutral background, consistent lighting., The hero. Determined, mid-30s."
        ),
        GenerationJob(
            id: "job-2",
            itemName: "City Street",
            itemType: .location,
            jobType: .generatePanel,
            size: .large,
            lookName: "Photorealistic",
            queuedAt: Date().addingTimeInterval(-120),
            estimatedDuration: 600,
            itemIcon: "map",
            itemLocationSetting: .exterior,
            seed: Int64.random(in: 1...999_999),
            width: 1920,
            height: 1080,
            combinedPrompt: "cinematic lighting, photorealistic, 8k resolution, urban environment, night scene, noir atmosphere, rain-soaked streets",
            variantCount: 0,
            attachedAssets: [
                JobAssetInfo(id: "a1", name: "The Hero", type: .character, icon: "person.fill", gender: .male)
            ]
        )
    ]
}
