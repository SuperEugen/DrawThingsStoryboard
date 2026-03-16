import SwiftUI

/// Right pane — switches between briefing detail, casting detail, and generic detail.
struct ItemDetailView: View {

    let section: AppSection?

    // Briefing hierarchy (mutable for editing name/rules)
    @Binding var studios: [MockStudio]
    let selectedStudioID: String?
    let selectedCustomerID: String?
    let selectedEpisodeID: String?
    let selectedBriefingLevel: BriefingLevel

    // Casting
    @Binding var selectedCastingItem: CastingItem?

    // Generic
    let selectedItemID: String?

    var body: some View {
        switch section {
        case .briefing:
            BriefingDetailView(
                studios: $studios,
                selectedStudioID: selectedStudioID,
                selectedCustomerID: selectedCustomerID,
                selectedEpisodeID: selectedEpisodeID,
                level: selectedBriefingLevel
            )
        case .casting:
            if let item = selectedCastingItem {
                CastingItemDetailView(item: Binding(
                    get: { item },
                    set: { selectedCastingItem = $0 }
                ))
            } else {
                emptyState
            }
        default:
            if let itemID = selectedItemID,
               let item = MockData.items(for: section).first(where: { $0.id == itemID }) {
                GenericDetailView(item: item)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an item to see its properties.")
        )
    }
}

// MARK: - Briefing detail

/// Shows Name and Rules for the selected Studio, Customer, or Episode.
struct BriefingDetailView: View {

    @Binding var studios: [MockStudio]
    let selectedStudioID: String?
    let selectedCustomerID: String?
    let selectedEpisodeID: String?
    let level: BriefingLevel

    // MARK: - Index helpers

    private var studioIndex: Int? {
        studios.firstIndex { $0.id == selectedStudioID }
    }
    private var customerIndex: Int? {
        guard let si = studioIndex else { return nil }
        return studios[si].customers.firstIndex { $0.id == selectedCustomerID }
    }
    private var episodeIndex: Int? {
        guard let si = studioIndex, let ci = customerIndex else { return nil }
        return studios[si].customers[ci].episodes.firstIndex { $0.id == selectedEpisodeID }
    }

    // MARK: - Bindings into the correct level

    private var nameBinding: Binding<String> {
        switch level {
        case .studio:
            guard let si = studioIndex else { return .constant("") }
            return $studios[si].name
        case .customer:
            guard let si = studioIndex, let ci = customerIndex else { return .constant("") }
            return $studios[si].customers[ci].name
        case .episode:
            guard let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return .constant("") }
            return $studios[si].customers[ci].episodes[ei].name
        }
    }

    private var rulesBinding: Binding<String> {
        switch level {
        case .studio:
            guard let si = studioIndex else { return .constant("") }
            return $studios[si].rules
        case .customer:
            guard let si = studioIndex, let ci = customerIndex else { return .constant("") }
            return $studios[si].customers[ci].rules
        case .episode:
            guard let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return .constant("") }
            return $studios[si].customers[ci].episodes[ei].rules
        }
    }

    private var themeColor: Color {
        switch level {
        case .studio:   return .purple
        case .customer: return .teal
        case .episode:  return .blue
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Type badge header
                BriefingTypeHeader(level: level, color: themeColor)

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                // Rules
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Rules")
                    Text("Prompt fragment applied to all images at this level.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    TextEditor(text: rulesBinding)
                        .font(.callout)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 16)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Briefing type header

private struct BriefingTypeHeader: View {
    let level: BriefingLevel
    let color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .overlay {
                    Image(systemName: level.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(color.opacity(0.6))
                }
            Text(level.label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.secondary)
                .padding(10)
        }
    }
}

// MARK: - Casting detail

struct CastingItemDetailView: View {
    @Binding var item: CastingItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailSection(item: item)
                StatusSection(item: $item)
                Divider().padding(.vertical, 8)
                LibraryLevelSection(item: $item)
                Divider().padding(.vertical, 8)
                NameSection(item: $item)
                if item.type == .character {
                    GenderSection(item: $item)
                } else {
                    LocationSettingSection(item: $item)
                }
                DescriptionSection(item: $item)
                Divider().padding(.vertical, 8)
                VariantsSection(item: $item)
                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - ThumbnailSection

private struct ThumbnailSection: View {
    let item: CastingItem
    private var typeLabel: String     { item.type == .character ? "Character" : "Location" }
    private var thumbnailColor: Color { item.type == .character ? .blue : .teal }
    private var thumbnailIcon: String {
        if item.type == .character {
            return item.gender?.icon ?? "person.fill"
        } else {
            return item.locationSetting?.icon ?? "map"
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(thumbnailColor.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .overlay {
                    Image(systemName: thumbnailIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(thumbnailColor.opacity(0.6))
                }
            Text(typeLabel)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.secondary)
                .padding(10)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - StatusSection (compact: single-line + context-dependent action)

private struct StatusSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")
            HStack(spacing: 8) {
                Circle()
                    .fill(item.status.color)
                    .frame(width: 8, height: 8)
                Text(item.status.label)
                    .font(.callout)
                Spacer()
                statusAction
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.07))
            )
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var statusAction: some View {
        switch item.status {
        case .nothingGenerated:
            Button {
                // TODO: trigger variant generation
            } label: {
                Label("Generate Variants", systemImage: "play.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        case .variantsGenerated:
            Text("Approve a variant below")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .variantApproved:
            Button {
                // TODO: trigger final generation
            } label: {
                Label("Generate Final", systemImage: "checkmark.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        case .finalGenerated:
            EmptyView()
        }
    }
}

// MARK: - LibraryLevelSection (compact: single-line + promote button)

private struct LibraryLevelSection: View {
    @Binding var item: CastingItem

    /// The next higher library level, or nil if already at studio.
    private var nextLevel: LibraryLevel? {
        switch item.libraryLevel {
        case .episode:  return .customer
        case .customer: return .studio
        case .studio:   return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Library level")
            HStack(spacing: 8) {
                Image(systemName: item.libraryLevel.icon)
                    .frame(width: 16)
                    .foregroundStyle(.secondary)
                Text(item.libraryLevel.rawValue)
                    .font(.callout)
                Spacer()
                if let next = nextLevel {
                    Button {
                        item.libraryLevel = next
                    } label: {
                        Label("Promote to \(next.rawValue)", systemImage: "arrow.up.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.07))
            )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - GenderSection

private struct GenderSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Gender")
            Picker("Gender", selection: Binding(
                get: { item.gender ?? .male },
                set: { item.gender = $0 }
            )) {
                ForEach(CharacterGender.allCases, id: \.rawValue) { g in
                    Label(g.label, systemImage: g.icon).tag(g)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - LocationSettingSection

private struct LocationSettingSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Setting")
            Picker("Setting", selection: Binding(
                get: { item.locationSetting ?? .interior },
                set: { item.locationSetting = $0 }
            )) {
                ForEach(LocationSetting.allCases, id: \.rawValue) { s in
                    Label(s.label, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - NameSection

private struct NameSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Name")
            TextField("Name", text: $item.name)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - DescriptionSection

private struct DescriptionSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Description")
            TextEditor(text: $item.description)
                .font(.callout)
                .frame(minHeight: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - VariantsSection (4 variant thumbnails with approve / delete)

private struct VariantsSection: View {
    @Binding var item: CastingItem

    private var placeholderIcon: String {
        if item.type == .character {
            return item.gender?.icon ?? "person.fill"
        } else {
            return item.locationSetting?.icon ?? "map"
        }
    }

    private var themeColor: Color {
        item.type == .character ? .blue : .teal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Variants")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { idx in
                    variantTile(index: idx)
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func variantTile(index idx: Int) -> some View {
        let variant = item.variants[idx]
        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(variant.isGenerated ? themeColor.opacity(0.2) : Color.secondary.opacity(0.08))
                    .frame(height: 72)
                    .overlay {
                        Image(systemName: placeholderIcon)
                            .font(.system(size: 24))
                            .foregroundStyle(variant.isGenerated ? themeColor : Color.secondary.opacity(0.3))
                    }

                // Delete button (top-right) — only if variant is generated
                if variant.isGenerated {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                deleteVariant(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(3)
                        }
                        Spacer()
                    }
                }

                // Approved badge (top-left)
                if variant.isApproved {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.green)
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(variant.isApproved ? Color.green : Color.clear, lineWidth: 1.5)
            )

            // Approve / Disapprove controls — only if variant is generated
            if variant.isGenerated {
                HStack(spacing: 8) {
                    Button {
                        approveVariant(at: idx)
                    } label: {
                        Image(systemName: variant.isApproved ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption2)
                            .foregroundStyle(variant.isApproved ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        disapproveVariant(at: idx)
                    } label: {
                        Image(systemName: "hand.thumbsdown")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!variant.isApproved)
                }
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
    }

    // MARK: - Actions

    private func approveVariant(at idx: Int) {
        // Clear any existing approval
        for i in 0..<item.variants.count {
            item.variants[i].isApproved = false
        }
        item.variants[idx].isApproved = true
        item.status = .variantApproved
    }

    private func disapproveVariant(at idx: Int) {
        item.variants[idx].isApproved = false
        // If no variant is approved, drop back to variantsGenerated (if all 4 generated)
        if item.approvedIndex == nil {
            item.status = item.generatedCount == 4 ? .variantsGenerated : .nothingGenerated
        }
    }

    private func deleteVariant(at idx: Int) {
        let wasApproved = item.variants[idx].isApproved
        item.variants[idx].isGenerated = false
        item.variants[idx].isApproved = false

        // Recalculate status
        if wasApproved || item.approvedIndex == nil {
            item.status = item.generatedCount == 4 ? .variantsGenerated : .nothingGenerated
        }
    }
}

// MARK: - Generic detail

private struct GenericDetailView: View {
    let item: MockItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(item.color)
                    }
                Text(item.name).font(.title3.bold())
                Divider()
                LabeledContent("Status")   { Text(item.status).foregroundStyle(.secondary) }
                LabeledContent("Variants") { Text("\(item.variantCount)").foregroundStyle(.secondary) }
                LabeledContent("ID")       { Text(item.id).font(.caption.monospaced()).foregroundStyle(.tertiary) }
                Spacer()
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Shared free function

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}

#Preview("Casting") {
    @Previewable @State var studios = MockData.defaultStudios
    @Previewable @State var item: CastingItem? = MockData.castingCharacters.first
    ItemDetailView(
        section: .casting,
        studios: $studios,
        selectedStudioID: MockData.defaultStudios[0].id,
        selectedCustomerID: MockData.defaultStudios[0].customers[0].id,
        selectedEpisodeID: MockData.defaultStudios[0].customers[0].episodes[0].id,
        selectedBriefingLevel: .episode,
        selectedCastingItem: $item,
        selectedItemID: nil
    )
    .frame(width: 280, height: 700)
}
#Preview("Briefing") {
    @Previewable @State var studios = MockData.defaultStudios
    @Previewable @State var item: CastingItem? = nil
    ItemDetailView(
        section: .briefing,
        studios: $studios,
        selectedStudioID: MockData.defaultStudios[0].id,
        selectedCustomerID: MockData.defaultStudios[0].customers[0].id,
        selectedEpisodeID: MockData.defaultStudios[0].customers[0].episodes[0].id,
        selectedBriefingLevel: .studio,
        selectedCastingItem: $item,
        selectedItemID: nil
    )
    .frame(width: 280, height: 700)
}

