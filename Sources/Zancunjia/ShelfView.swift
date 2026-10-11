import AppKit
import SwiftUI
import ZancunjiaCore

struct ShelfView: View {
    var model: ShelfModel
    var chrome: ShelfChrome
    var settings: ShelfSettings

    var body: some View {
        switch settings.placement {
        case .sidebar:
            shelfSurface(sidebarContent, shape: panelShape, dark: false)
        case .island:
            islandBody
                .environment(\.colorScheme, .dark)
        case .dock:
            if chrome.isExpanded {
                shelfSurface(canvas, shape: dockSheetShape, dark: false)
            } else {
                shelfSurface(dockPill, shape: Capsule(style: .continuous), dark: false)
            }
        }
    }

    private func shelfSurface<S: InsettableShape>(_ content: some View, shape: S, dark: Bool) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(ShelfGlass(shape: shape, dark: dark, appearance: settings.appearance))
            .id(settings.appearance)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(dark ? 0.38 : 0.62), Color.white.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
            }
            .overlay {
                if chrome.dropTargeted {
                    shape.strokeBorder(Color.accentColor, lineWidth: 2).padding(3)
                }
            }
    }

    private var sidebarContent: some View {
        HStack(spacing: 0) {
            if settings.edge == .left {
                tab
                if chrome.isExpanded { canvas }
            } else {
                if chrome.isExpanded { canvas }
                tab
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: settings.edge == .left ? .leading : .trailing)
    }

    private var islandBody: some View {
        islandContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                IslandPlate(radius: islandRadius)
            }
            .overlay {
                if chrome.dropTargeted {
                    islandMask.stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                }
            }
    }

    /// Flat against the top edge, round only on the bottom. The collapsed pill is a
    /// semicircle; the open sheet uses a short corner, matching the island on screen.
    private var islandRadius: CGFloat {
        chrome.isExpanded ? 22 : 16
    }

    private var islandMask: IslandMask {
        IslandMask(radius: islandRadius)
    }

    private var islandContent: some View {
        Group {
            if chrome.isExpanded {
                islandExpanded
            } else {
                islandPill
            }
        }
    }

    private var islandPill: some View {
        Button(action: chrome.togglePin) {
            HStack(spacing: 0) {
                islandEar
                Spacer(minLength: 0)
                if !model.items.isEmpty {
                    Text("\(model.items.count)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(L10n.t("help.expand_drop"))
        .accessibilityLabel(model.items.isEmpty ? L10n.t("a11y.capsule.empty") : L10n.format("a11y.capsule.count", model.items.count))
        .accessibilityHint(L10n.t("a11y.expand_drop"))
    }

    @ViewBuilder
    private var islandEar: some View {
        if let latest = model.items.first {
            CachedImage(data: latest.thumbnailPNG)
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        } else {
            Image(systemName: "photo")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var islandExpanded: some View {
        VStack(spacing: 0) {
            islandHeader
            if model.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(settings.captureEnabled ? L10n.t("empty.media_here") : L10n.t("empty.paused"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))
                    Text(settings.captureEnabled
                         ? L10n.t("empty.privacy")
                         : L10n.t("empty.drag_capsule"))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.42))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(model.items) { item in
                            islandRow(item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    /// Sits in the menu-bar band. The title stays in the left ear and the buttons
    /// in the right ear, so the camera housing in the middle stays empty.
    private var islandHeader: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "photo")
                    .font(.system(size: 12, weight: .semibold))
                Text(islandCountTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
            Button(action: chrome.togglePin) {
                Image(systemName: chrome.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(chrome.isPinned ? L10n.t("action.unpin") : L10n.t("action.pin"))
            .accessibilityLabel(chrome.isPinned ? L10n.t("action.unpin") : L10n.t("action.pin"))
            Button {
                model.clear(undoable: true)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(model.items.isEmpty ? 0.28 : 0.92))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(model.items.isEmpty)
            .help(L10n.t("action.clear"))
            .accessibilityLabel(L10n.t("action.clear"))
        }
        .padding(.horizontal, 22)
        .frame(height: 34)
    }

    private var islandCountTitle: String {
        if !model.selectedIDs.isEmpty { return L10n.format("status.selected", model.selectedIDs.count) }
        return model.items.isEmpty ? L10n.t("action.stash") : L10n.format("status.items", model.items.count)
    }

    private static let islandDateStyle = Date.FormatStyle(date: .omitted, time: .standard)
        .locale(.autoupdatingCurrent)

    private func islandClock(_ date: Date) -> String {
        date.formatted(Self.islandDateStyle)
    }

    private func islandRow(_ item: ScratchItem) -> some View {
        ZStack {
            HStack(spacing: 12) {
                CachedImage(data: item.thumbnailPNG)
                    .frame(width: 52, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(islandClock(item.createdAt))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    TimelineView(.periodic(from: item.createdAt, by: 30)) { context in
                        Text("\(item.pixelWidth)×\(item.pixelHeight) · \(formatAge(item.createdAt, now: context.date))")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(itemTag(item))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.14), in: Capsule())
                Color.clear.frame(width: 18, height: 18)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                model.selectedIDs.contains(item.id) ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(model.selectedIDs.contains(item.id) ? Color.accentColor : .clear, lineWidth: 2)
            }
            DragThumb(
                item: item,
                dragItems: model.itemsForAction(startingWith: item.id),
                onClick: { handleClick(item, modifiers: $0) },
                onQuickLook: { preview(item) },
                onClearSelection: model.clearSelection
            )
            HStack {
                Spacer(minLength: 0)
                Button {
                    withAnimation(.snappy(duration: 0.22)) { model.remove(item.id, undoable: true) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .help(L10n.t("action.remove"))
                .accessibilityLabel(L10n.t("action.remove"))
            }
            .padding(.trailing, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mediaAccessibilityLabel(for: item))
        .accessibilityHint(L10n.t("a11y.item_hint"))
        .help(L10n.t("help.click_copy"))
        .accessibilityAction(named: model.selectedIDs.contains(item.id) ? L10n.t("action.deselect") : L10n.t("action.select")) {
            model.toggleSelection(item.id)
        }
        .accessibilityAction(named: L10n.t("action.preview")) { preview(item) }
    }

    private func handleClick(_ item: ScratchItem, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            model.toggleSelection(item.id)
        } else {
            model.copy(item.id)
        }
    }

    private func preview(_ item: ScratchItem) {
        ShelfQuickLook.shared.show(
            items: model.itemsForAction(startingWith: item.id),
            startingWith: item.id
        )
    }

    private var dockSheetShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: ShelfGeometry.cornerRadius, style: .continuous)
    }

    private var dockPill: some View {
        Button(action: chrome.togglePin) {
            Group {
                if chrome.dockSide == .bottom {
                    HStack(spacing: 8) {
                        dockGlyph
                        dockCount
                    }
                } else {
                    VStack(spacing: 6) {
                        dockGlyph
                        dockCount
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .help(L10n.t("help.pin_drop"))
        .accessibilityLabel(model.items.isEmpty ? L10n.t("a11y.dock.empty") : L10n.format("a11y.dock.count", model.items.count))
        .accessibilityHint(L10n.t("a11y.expand_drop"))
    }

    private var dockGlyph: some View {
        Group {
            if let latest = model.items.first {
                CachedImage(data: latest.thumbnailPNG)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var dockCount: some View {
        Text(model.items.isEmpty ? L10n.t("action.stash") : "\(model.items.count)")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
    }

    private var panelShape: UnevenRoundedRectangle {
        let radius = ShelfGeometry.cornerRadius
        return switch settings.edge {
        case .left:
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: radius,
                topTrailingRadius: radius,
                style: .continuous
            )
        case .right:
            UnevenRoundedRectangle(
                topLeadingRadius: radius,
                bottomLeadingRadius: radius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        }
    }

    private var tab: some View {
        VStack(spacing: 10) {
            Image(systemName: chevron)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            if let latest = model.items.first {
                CachedImage(data: latest.thumbnailPNG)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
                    }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 15, weight: .medium))
                    .symbolEffect(.bounce, value: model.arrivalCount)
            }
            Text(model.items.isEmpty ? L10n.t("action.stash") : "\(model.items.count)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Circle()
                .fill(chrome.isPinned ? Color.accentColor : Color.clear)
                .frame(width: 5, height: 5)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .frame(width: ShelfGeometry.tabWidth)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .help(chrome.isPinned ? L10n.t("help.tab_pinned") : L10n.t("help.tab_unpinned"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.format("a11y.sidebar", model.items.count))
        .accessibilityHint(chrome.isPinned ? L10n.t("a11y.tab_pinned") : L10n.t("a11y.tab_unpinned"))
    }

    private var chevron: String {
        switch settings.edge {
        case .left:
            chrome.isExpanded ? "chevron.left" : "chevron.right"
        case .right:
            chrome.isExpanded ? "chevron.right" : "chevron.left"
        }
    }

    private var canvas: some View {
        VStack(spacing: 0) {
            header
            if model.items.isEmpty {
                empty
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(model.items) { item in
                            ScreenshotCell(model: model, item: item, imageHeight: cellHeight)
                        }
                    }
                    .padding(14)
                }
                .scrollContentBackground(.hidden)
                Text(footerHint)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if let notice = model.notice {
                Text(notice)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 36)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.snappy(duration: 0.2), value: model.notice)
        .animation(.snappy(duration: 0.25), value: model.items.count)
    }

    private var columns: [GridItem] {
        if model.items.count == 1 {
            [GridItem(.flexible())]
        } else {
            [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        }
    }

    private var cellHeight: CGFloat {
        model.items.count == 1 ? 220 : 124
    }

    private var footerHint: String {
        model.selectedIDs.isEmpty
            ? L10n.t("footer.click_copy")
            : L10n.format("footer.selected", model.selectedIDs.count)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SnapShelf")
                    .font(.system(size: 13, weight: .semibold))
                Text(headerSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            pinButton
            Button(L10n.t("action.clear")) { model.clear(undoable: true) }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .disabled(model.items.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var headerSubtitle: String {
        if model.items.isEmpty {
            return settings.captureEnabled ? L10n.t("header.idle_collect") : L10n.t("header.idle_paused")
        }
        return settings.captureEnabled
            ? L10n.format("header.count_collect", model.items.count)
            : L10n.format("header.count_paused", model.items.count)
    }

    private var pinButton: some View {
        Button(action: chrome.togglePin) {
            Image(systemName: chrome.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(
                    chrome.isPinned ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .help(chrome.isPinned ? L10n.t("action.unpin") : L10n.t("action.pin"))
        .accessibilityLabel(chrome.isPinned ? L10n.t("action.unpin") : L10n.t("action.pin"))
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
            Text(settings.captureEnabled ? L10n.t("empty.media_here") : L10n.t("empty.paused"))
                .font(.system(size: 13, weight: .semibold))
            Text(settings.captureEnabled
                 ? L10n.t("empty.sidebar_capture")
                 : L10n.t("empty.sidebar_paused"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ScreenshotCell: View {
    let model: ShelfModel
    let item: ScratchItem
    var imageHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                CachedImage(data: item.thumbnailPNG)
                if item.isLivePhoto {
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "livephoto")
                                .font(.system(size: 9, weight: .semibold))
                            Text("LIVE")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.55), in: Capsule())
                        Spacer()
                    }
                    .padding(6)
                } else if item.isVideo {
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 7, weight: .semibold))
                            if let duration = item.duration {
                                Text(formatDuration(duration))
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.55), in: Capsule())
                        Spacer()
                    }
                    .padding(6)
                }
                DragThumb(
                    item: item,
                    dragItems: model.itemsForAction(startingWith: item.id),
                    onClick: handleClick,
                    onQuickLook: preview,
                    onClearSelection: model.clearSelection
                )
                Button(action: remove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
                .help(L10n.t("action.remove"))
                .accessibilityLabel(L10n.t("action.remove"))
            }
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        model.selectedIDs.contains(item.id) ? Color.accentColor : Color.white.opacity(0.45),
                        lineWidth: model.selectedIDs.contains(item.id) ? 2 : 0.6
                    )
            }
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

            TimelineView(.periodic(from: item.createdAt, by: 30)) { context in
                Text(subtitle(for: item, now: context.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mediaAccessibilityLabel(for: item))
        .accessibilityHint(L10n.t("a11y.item_hint"))
        .help(L10n.t("help.click_copy"))
        .accessibilityAction(named: model.selectedIDs.contains(item.id) ? L10n.t("action.deselect") : L10n.t("action.select")) {
            model.toggleSelection(item.id)
        }
        .accessibilityAction(named: L10n.t("action.preview"), preview)
        .accessibilityAction(named: L10n.t("action.remove"), remove)
    }

    private func handleClick(_ modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            model.toggleSelection(item.id)
        } else {
            model.copy(item.id)
        }
    }

    private func preview() {
        ShelfQuickLook.shared.show(
            items: model.itemsForAction(startingWith: item.id),
            startingWith: item.id
        )
    }

    private func remove() {
        withAnimation(.snappy(duration: 0.22)) {
            model.remove(item.id, undoable: true)
        }
    }
}

private struct CachedImage: View {
    let data: Data
    @State private var image: NSImage?

    var body: some View {
        Color.clear
            .overlay {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped()
            .task(id: data) {
                image = nil
                let decoded = await Task.detached(priority: .userInitiated) {
                    NSImage(data: data)
                }.value
                if !Task.isCancelled { image = decoded }
            }
    }
}

private func formatAge(_ date: Date, now: Date) -> String {
    let seconds = now.timeIntervalSince(date)
    if seconds < 45 { return L10n.t("time.just_now") }
    if seconds < 3600 { return L10n.format("time.minutes_ago", max(1, Int(seconds / 60))) }
    return date.formatted(date: .omitted, time: .shortened)
}

@MainActor
private func itemTag(_ item: ScratchItem) -> String {
    switch item.kind {
    case .livePhoto:
        return "LIVE"
    case .video:
        let ext = item.fileURL.pathExtension.uppercased()
        return ext.isEmpty ? "VIDEO" : ext
    case .image:
        let ext = item.fileURL.pathExtension.uppercased()
        return ext.isEmpty ? "PNG" : ext
    }
}

@MainActor
private func subtitle(for item: ScratchItem, now: Date) -> String {
    let ageStr = formatAge(item.createdAt, now: now)
    switch item.kind {
    case .livePhoto:
        return L10n.format("subtitle.live", item.pixelWidth, item.pixelHeight, ageStr)
    case .video:
        let dur = formatDuration(item.duration)
        return L10n.format("subtitle.video", item.pixelWidth, item.pixelHeight, dur, ageStr)
    case .image:
        return L10n.format("subtitle.image", item.pixelWidth, item.pixelHeight, ageStr)
    }
}

@MainActor
private func mediaAccessibilityLabel(for item: ScratchItem) -> String {
    switch item.kind {
    case .livePhoto:
        return L10n.format("a11y.live_photo", item.pixelWidth, item.pixelHeight)
    case .video:
        return L10n.format("a11y.video", item.pixelWidth, item.pixelHeight, formatDuration(item.duration))
    case .image:
        return L10n.format("a11y.image", item.pixelWidth, item.pixelHeight)
    }
}

private func formatDuration(_ duration: TimeInterval?) -> String {
    guard let duration, duration > 0 else { return "00:00" }
    let totalSeconds = Int(duration.rounded())
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

private struct IslandPlate: NSViewRepresentable {
    var radius: CGFloat

    func makeNSView(context: Context) -> IslandPlateView {
        let view = IslandPlateView()
        view.radius = radius
        return view
    }

    func updateNSView(_ view: IslandPlateView, context: Context) {
        view.radius = radius
    }
}

/// Paints the notch itself. A SwiftUI color gets cleared with the hosting view's plate.
private final class IslandPlateView: NSView {
    var radius: CGFloat = 16 { didSet { needsDisplay = true } }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        let lift = min(radius, bounds.height)
        let body = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height + lift)
        context.addPath(CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.fillPath()
    }
}

private struct IslandMask: InsettableShape {
    var radius: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let lift = min(radius, rect.height)
        let body = CGRect(x: rect.minX, y: rect.minY - lift, width: rect.width, height: rect.height + lift)
        return Path(roundedRect: body, cornerRadius: radius, style: .continuous)
    }

    func inset(by amount: CGFloat) -> IslandMask {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

/// macOS 26 draws the plate with the shelf window's glass view.
/// Earlier systems use a material behind the content.
private struct ShelfGlass<S: Shape>: ViewModifier {
    var shape: S
    var dark: Bool = false
    var appearance: ShelfAppearance

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            // The plate is an NSGlassEffectView behind this content.
            content
        } else if dark {
            content.background(Color.black.opacity(0.78), in: shape)
        } else {
            content
                .background(appearance == .regular ? .regularMaterial : .ultraThinMaterial)
                .clipShape(shape)
        }
    }
}

