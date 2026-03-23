import SwiftUI

// MARK: - Casting detail (used by Assets)

struct CastingItemDetailView: View {
    @Binding var item: CastingItem
    @Binding var generationQueue: [GenerationJob]
    /// Called when the user promotes or demotes the library level.
    var onLevelChange: ((LibraryLevel) -> Void)? = nil
    /// Called when the user moves an episode-level item to the next episode.
    var onMoveToNextEpisode: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailSection(item: item)
                StatusSection(item: $item, generationQueue: $generationQueue)
                Divider().padding(.vertical, 8)
                LibraryLevelSection(item: $item, onLevelChange: onLevelChange, onMoveToNextEpisode: onMoveToNextEpisode)
                Divider().padding(.vertical, 8)
                NameSection(item: $item)
                // Read-only type indicator
                AssetTypeIndicator(type: item.type)
                if item.type == .character {
                    GenderSection(item: $item)
                } else {
                    LocationSettingSection(item: $item)
                }
                DescriptionSection(item: $item)
                Divider().padding(.vertical, 8)
                VariantsSection(item: $item, generationQueue: $generationQueue)
                // File Name (read-only)
                if !item.fileName.isEmpty {
                    Divider().padding(.vertical, 8)
                    FileNameSection(fileName: item.fileName)
                }
                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Asset type indicator (read-only)

private struct AssetTypeIndicator: View {
    let type: CastingItemType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Type")
            HStack(spacing: 6) {
                Image(systemName: type == .character ? "person.fill" : "map")
                    .foregroundStyle(type == .character ? .blue : .teal)
                    .frame(width: 16)
                Text(type == .character ? "Character" : "Location")
                    .font(.callout)
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

// MARK: - FileNameSection (read-only)

private struct FileNameSection: View {
    let fileName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("File Name")
            Text(fileName)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.accentColor.opacity(0.07))
                )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - ThumbnailSection

private struct ThumbnailSection: View {
    let item: CastingItem

    var body: some View {
        UnifiedThumbnailView(
            itemType: item.thumbnailType,
            name: "",
            sizeMode: .header
        )
        .padding(.bottom, 16)
    }
}

// MARK: - StatusSection (three-row V/S/L status display)

private struct StatusSection: View {
    @Binding var item: CastingItem
    @Binding var generationQueue: [GenerationJob]

    @AppStorage(SizeConfigKeys.finalWidth)  private var finalWidth  = SizeConfigDefaults.finalWidth
    @AppStorage(SizeConfigKeys.finalHeight) private var finalHeight = SizeConfigDefaults.finalHeight

    private var largeImageQueued: Bool {
        generationQueue.contains { $0.itemName == item.name && $0.jobType == .generateAsset && $0.size == .large }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")

            statusRow(
                label: "Variants generated:",
                value: item.variantsAvailable ? "yes" : "not yet",
                isActive: item.variantsAvailable
            )

            statusRow(
                label: "Small Image available:",
                value: item.smallImageAvailable ? "yes" : "no Variant approved",
                isActive: item.smallImageAvailable
            )

            HStack(spacing: 8) {
                Text("L")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(item.largeImageAvailable ? .green : .gray)
                Text("Large Image available:")
                    .font(.callout)
                Text(item.largeImageAvailable ? "yes" : (item.smallImageAvailable ? "not yet" : "no Variant approved"))
                    .font(.callout)
                    .foregroundStyle(item.largeImageAvailable ? .green : .secondary)
                Spacer()

                if item.smallImageAvailable && !item.largeImageAvailable {
                    if largeImageQueued {
                        Text("queued")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            queueLargeImageJob()
                        } label: {
                            Label("Generate Large Image", systemImage: "photo.badge.checkmark")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
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

    @ViewBuilder
    private func statusRow(label: String, value: String, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Text(label == "Variants generated:" ? "V" : "S")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? .green : .gray)
            Text(label)
                .font(.callout)
            Text(value)
                .font(.callout)
                .foregroundStyle(isActive ? .green : .secondary)
            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.accentColor.opacity(0.07))
        )
    }

    private func queueLargeImageJob() {
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: item.name,
            itemType: item.type,
            jobType: .generateAsset,
            size: .large,
            lookName: item.type == .character ? "Character Final" : "Location Final",
            queuedAt: Date(),
            estimatedDuration: 180,
            itemIcon: item.type == .character ? (item.gender?.icon ?? "person.fill") : (item.locationSetting?.icon ?? "map"),
            itemGender: item.gender,
            itemLocationSetting: item.locationSetting,
            seed: Int64.random(in: 1...999_999),
            width: finalWidth,
            height: finalHeight,
            combinedPrompt: item.description
        )
        generationQueue.append(job)
    }
}

// MARK: - LibraryLevelSection (promote + demote buttons)

private struct LibraryLevelSection: View {
    @Binding var item: CastingItem
    /// Called when the user promotes or demotes — the parent handles the actual tree move.
    var onLevelChange: ((LibraryLevel) -> Void)? = nil
    /// Called when the user moves an episode-level item to the next episode.
    var onMoveToNextEpisode: (() -> Void)? = nil

    /// The next higher library level, or nil if already at studio.
    private var promoteLevel: LibraryLevel? {
        switch item.libraryLevel {
        case .episode:  return .customer
        case .customer: return .studio
        case .studio:   return nil
        }
    }

    private var promoteLabel: String {
        guard let level = promoteLevel else { return "" }
        return "Promote to \(level.rawValue)"
    }

    /// The next lower library level label.
    private var demoteLabel: String {
        switch item.libraryLevel {
        case .studio:   return "Move to Customer"
        case .customer: return "Move to Episode"
        case .episode:  return "Move to next Episode"
        }
    }

    /// The level to demote to, or nil if already at episode (special case: move to next episode).
    private var demoteLevel: LibraryLevel? {
        switch item.libraryLevel {
        case .studio:   return .customer
        case .customer: return .episode
        case .episode:  return nil  // special: stays episode, moves to next
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
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.07))
            )

            // Promote / Demote buttons
            HStack(spacing: 6) {
                // Demote button
                Button {
                    if let level = demoteLevel {
                        onLevelChange?(level)
                    } else {
                        // Episode → next episode: stays at .episode
                        onMoveToNextEpisode?()
                    }
                } label: {
                    Label(demoteLabel, systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                // Promote button (only if not already at studio)
                if let level = promoteLevel {
                    Button {
                        onLevelChange?(level)
                    } label: {
                        Label(promoteLabel, systemImage: "arrow.up.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
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
    @Binding var generationQueue: [GenerationJob]

    @AppStorage(SizeConfigKeys.previewVariantWidth)  private var previewVariantWidth  = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight

    private var variantsQueued: Bool {
        generationQueue.contains { $0.itemName == item.name && $0.jobType == .generateAsset && $0.size == .small }
    }

    /// Number of empty variant slots (0–4).
    private var freeSlotCount: Int {
        item.variants.filter { !$0.isGenerated }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionLabel("Variants")
                Spacer()
                if variantsQueued {
                    Text("Generate Variants queued")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if freeSlotCount > 0 {
                    Button {
                        queueVariantsJob()
                    } label: {
                        Label("Generate \(freeSlotCount) Variant\(freeSlotCount == 1 ? "" : "s")", systemImage: "play.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(item.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { idx in
                    if idx < item.variants.count {
                        variantTile(index: idx)
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func variantTile(index idx: Int) -> some View {
        guard idx < item.variants.count else { return AnyView(EmptyView()) }
        let variant = item.variants[idx]
        return AnyView(VStack(spacing: 4) {
            UnifiedThumbnailView(
                itemType: item.thumbnailType,
                name: "",
                sizeMode: .standard,
                badges: ThumbnailBadges(
                    showDeleteButton: variant.isGenerated,
                    onDelete: { deleteVariant(at: idx) },
                    showApprovedBadge: variant.isApproved
                )
            )
            .opacity(variant.isGenerated ? 1.0 : 0.4)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
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
        }) // AnyView / VStack
    }

    // MARK: - Actions

    private func approveVariant(at idx: Int) {
        // Clear any existing approval
        for i in 0..<item.variants.count {
            item.variants[i].isApproved = false
        }
        item.variants[idx].isApproved = true
        item.smallImageAvailable = true
    }

    private func disapproveVariant(at idx: Int) {
        item.variants[idx].isApproved = false
        if item.approvedIndex == nil {
            item.smallImageAvailable = false
        }
    }

    private func deleteVariant(at idx: Int) {
        let wasApproved = item.variants[idx].isApproved
        item.variants[idx].isGenerated = false
        item.variants[idx].isApproved = false

        if wasApproved || item.approvedIndex == nil {
            item.smallImageAvailable = false
        }
    }

    private func queueVariantsJob() {
        let count = freeSlotCount
        guard count > 0 else { return }
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: item.name,
            itemType: item.type,
            jobType: .generateAsset,
            size: .small,
            lookName: item.type == .character ? "Standard Character" : "Location Establishing",
            queuedAt: Date(),
            estimatedDuration: TimeInterval(count) * 75,
            itemIcon: item.type == .character ? (item.gender?.icon ?? "person.fill") : (item.locationSetting?.icon ?? "map"),
            itemGender: item.gender,
            itemLocationSetting: item.locationSetting,
            seed: Int64.random(in: 1...999_999),
            width: previewVariantWidth,
            height: previewVariantHeight,
            combinedPrompt: item.description,
            variantCount: count
        )
        generationQueue.append(job)
    }
}
