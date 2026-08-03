//
//  WorkoutPhotoShareSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 14.07.26.
//


import SwiftUI
import PhotosUI

// MARK: - Keyfacts Overlay (Bold, horizontal/vertical)

private struct PhotoKeyfacts {
    let dateText: String
    let timeText: String
    let durationText: String
    let volumeText: String?
    let setsCount: Int
    let exercisesCount: Int
    let volumeSparkline: [Double]
}

private func formatVolume(_ kg: Double) -> String {
    if kg >= 1000 {
        let formatted = String(format: "%.1f", kg / 1000)
            .replacingOccurrences(of: ".", with: ",")
        return "\(formatted) t"
    }
    return "\(Int(kg)) kg"
}

private struct BoldKeyfactsOverlay: View {
    let kf: PhotoKeyfacts
    let tint: Color
    let orientation: OverlayOrientation

    var body: some View {
        Group {
            switch orientation {
            case .horizontal: horizontalLayout
            case .vertical:   verticalLayout
            }
        }
    }

    @ViewBuilder
    private var statsContent: some View {
        boldStat(kf.durationText, "Dauer")
        boldStat("\(kf.setsCount)", "Sätze")
        boldStat("\(kf.exercisesCount)", "Übungen")
        if let vol = kf.volumeText { boldStat(vol, "Volumen") }
    }

    private var dateTimeHeader: some View {
        Text("\(kf.dateText) · \(kf.timeText)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 3)
    }

    private var sparkline: some View {
        VStack(spacing: 2) {
            Canvas { context, size in
                let values = kf.volumeSparkline
                guard values.count > 1 else { return }
                let maxVal = values.max() ?? 1
                let minVal = values.min() ?? 0
                let range = max(maxVal - minVal, 1)
                let stepX = size.width / CGFloat(values.count - 1)

                var path = Path()
                for (i, v) in values.enumerated() {
                    let x = CGFloat(i) * stepX
                    let normalized = CGFloat((v - minVal) / range)
                    let y = size.height - normalized * size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(tint), lineWidth: 2.5)

                var fillPath = path
                fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
                fillPath.addLine(to: CGPoint(x: 0, y: size.height))
                fillPath.closeSubpath()
                context.fill(fillPath, with: .color(tint.opacity(0.25)))
            }
            .frame(width: 120, height: 32)

            Text("Verlauf")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)
        }
        .accessibilityHidden(true)
    }

    private var horizontalLayout: some View {
        VStack(spacing: 10) {
            dateTimeHeader
            HStack(spacing: 24) {
                statsContent
            }
            sparkline
        }
    }

    private var verticalLayout: some View {
        VStack(spacing: 10) {
            dateTimeHeader
            VStack(spacing: 12) {
                statsContent
            }
            sparkline
        }
    }

    private func boldStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.6), radius: 6)
                .shadow(color: .black.opacity(0.5), radius: 4)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 3)
        }
    }
}

enum OverlayOrientation: String, CaseIterable, Identifiable {
    case horizontal
    case vertical
    var id: String { rawValue }

    var label: String {
        switch self {
        case .horizontal: "Horizontal"
        case .vertical: "Vertikal"
        }
    }

    var icon: String {
        switch self {
        case .horizontal: "rectangle.split.3x1"
        case .vertical: "rectangle.split.1x3"
        }
    }
}

// MARK: - Main Sheet

struct WorkoutPhotoShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var photoItem: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    @State private var canvasSize: CGSize = CGSize(width: 360, height: 460)

    @State private var overlayColor: Color = .blue
    @State private var overlayOrientation: OverlayOrientation = .horizontal
    // Normalized: fraction of canvas size (-0.5 ... 0.5 from center)
    @State private var overlayOffsetX: CGFloat = 0
    @State private var overlayOffsetY: CGFloat = 0
    @GestureState private var dragTranslation: CGSize = .zero

    private let exportWidth: CGFloat = 2160
    private let overlayDesignWidth: CGFloat = 360

    private var data: SummaryData {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        let sorted: [(Exercise, [SetEntry])]
        if let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }), !plan.isEmpty {
            var result: [(Exercise, [SetEntry])] = []
            for slot in plan {
                guard let ex = slot.exercise else { continue }
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                if !sets.isEmpty { result.append((ex, sets)) }
            }
            let unique = Set(session.sets.compactMap { $0.exercise })
            for ex in unique.sorted(by: { $0.name < $1.name }) {
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                if !sets.isEmpty && !plan.contains(where: { $0.exercise?.id == ex.id }) {
                    result.append((ex, sets))
                }
            }
            sorted = result
        } else {
            let unique = Set(session.sets.compactMap { $0.exercise })
            sorted = unique.sorted { $0.name < $1.name }.map { ex in
                (ex, (groups[ex.id] ?? []).sorted { $0.order < $1.order })
            }
        }
        return SummaryData(
            session: session,
            sortedExercises: sorted,
            totalVolumeKg: session.sets
                .filter { $0.exercise?.trackingType == .repsWeight && $0.isCompleted }
                .reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) },
            totalReps: session.sets
                .filter { guard let t = $0.exercise?.trackingType else { return false }; return (t == .reps || t == .repsWeight) && $0.isCompleted }
                .reduce(0) { $0 + ($1.reps ?? 0) },
            totalDistanceKm: session.sets
                .filter { $0.exercise?.trackingType == .distanceDuration && $0.isCompleted }
                .reduce(0) { $0 + ($1.distanceMeters ?? 0) } / 1000,
            activeDurationSeconds: session.sets
                .filter { $0.exercise?.trackingType == .duration && $0.isCompleted }
                .reduce(0) { $0 + ($1.durationSeconds ?? 0) },
            completedSets: session.sets.filter(\.isCompleted).count,
            totalSets: session.sets.count
        )
    }

    private var keyfacts: PhotoKeyfacts {
        PhotoKeyfacts(
            dateText: session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)),
            timeText: session.startedAt.formatted(.dateTime.hour().minute()),
            durationText: data.durationText,
            volumeText: data.totalVolumeKg > 0 ? formatVolume(data.totalVolumeKg) : nil,
            setsCount: data.completedSets,
            exercisesCount: data.exerciseCount,
            volumeSparkline: sparklineValues
        )
    }

    private var sparklineValues: [Double] {
        let completed = session.sets
            .filter { $0.isCompleted }
            .sorted { ($0.order) < ($1.order) }
        guard !completed.isEmpty else { return [] }
        return completed.map { set in
            guard let ex = set.exercise else { return 0 }
            switch ex.trackingType {
            case .repsWeight: return (set.weight ?? 0) * Double(set.reps ?? 0)
            case .reps:       return Double(set.reps ?? 0) * 60.0
            case .duration:   return Double(set.durationSeconds ?? 0) * 0.5
            case .distanceDuration: return (set.distanceMeters ?? 0) * 0.05
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            previewArea
            controls
        }
        .bentoActionBar {
            if let img = currentRenderedImage() {
                ShareLink(
                    item: Image(uiImage: img),
                    preview: SharePreview("Workout", image: Image(uiImage: img))
                ) {
                    BentoButton(
                        Text("Teilen"),
                        systemImage: "square.and.arrow.up",
                        variant: .primary,
                        expands: true
                    ) {}
                    .allowsHitTesting(false)
                }
            } else {
                BentoButton(
                    Text("Teilen"),
                    systemImage: "square.and.arrow.up",
                    variant: .primary,
                    expands: true
                ) {}
                .disabled(true)
            }
        }
        .onChange(of: photoItem) { _, item in
            Task {
                if let d = try? await item?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: d) {
                    backgroundImage = uiImage
                    resetPositions()
                }
            }
        }
    }

    /// Rendert das aktuelle Bild on-demand für den ShareLink.
    private func currentRenderedImage() -> UIImage? {
        guard let backgroundImage else { return nil }
        let ratio = backgroundImage.size.height / max(backgroundImage.size.width, 1)
        let exportSize = CGSize(width: exportWidth, height: exportWidth * ratio)
        let renderer = ImageRenderer(content: canvasView(size: exportSize))
        renderer.scale = 1.0
        return renderer.uiImage
    }

    // MARK: - Canvas (shared preview & export, normalized coords)

    @ViewBuilder
    private func canvasView(size: CGSize) -> some View {
        ZStack {
            if let backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            }

            BoldKeyfactsOverlay(kf: keyfacts, tint: overlayColor, orientation: overlayOrientation)
                .frame(width: overlayDesignWidth)
                .scaleEffect(size.width / overlayDesignWidth, anchor: .center)
                .offset(x: (overlayOffsetX + dragTranslation.width / canvasSize.width) * size.width,
                        y: (overlayOffsetY + dragTranslation.height / canvasSize.height) * size.height)
                .gesture(overlayDragGesture(in: size))
                .accessibilityHidden(true)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    // MARK: - Preview

    private var previewArea: some View {
        GeometryReader { geo in
            ZStack {
                Color(.secondarySystemBackground)

                if let backgroundImage {
                    canvasView(size: geo.size)
                } else {
                    placeholder(geo.size)
                }
            }
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, newSize in
                if newSize.width > 0 && newSize.height > 0 {
                    canvasSize = newSize
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 460)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        .padding(Theme.Spacing.l)
    }

    private func placeholder(_ size: CGSize) -> some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Wähle ein Bild aus deinem Fotoalbum")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Text("Bild auswählen")
                    .font(.headline)
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Controls

    private var controls: some View {
        BentoCard(style: .outlined, padding: .lg, radius: .large) {
            VStack(spacing: Theme.Spacing.m) {
                HStack {
                    BentoText(verbatim: "Farbe", style: .bodyStrong)
                    Spacer()
                    ColorPicker("", selection: $overlayColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 44, height: 36)
                }

                BentoDivider()

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    BentoText(verbatim: "Ausrichtung", style: .caption, color: .secondary)
                    BentoSegmentedPicker(options: OverlayOrientation.allCases, selection: $overlayOrientation) { o in
                        Text(verbatim: o.label)
                    }
                }

                if backgroundImage != nil {
                    BentoDivider()
                    HStack(spacing: Theme.Spacing.s) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            BentoButton(
                                Text("Bild ändern"),
                                systemImage: "photo",
                                variant: .secondary,
                                size: .small
                            ) {}
                            .allowsHitTesting(false)
                        }
                        Spacer()
                        BentoButton(
                            Text("Zurücksetzen"),
                            systemImage: "arrow.counterclockwise",
                            variant: .ghost,
                            size: .small
                        ) {
                            resetPositions()
                            Haptics.selection()
                        }
                    }

                    BentoBadge(
                        Text("Overlay ziehen zum Verschieben"),
                        tone: .info,
                        systemImage: "hand.draw"
                    )
                }

                if backgroundImage == nil {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        BentoButton(
                            Text("Bild auswählen"),
                            systemImage: "photo.badge.plus",
                            variant: .primary,
                            expands: true
                        ) {}
                        .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.l)
    }

    // MARK: - Drag Gesture

    private func overlayDragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                overlayOffsetX += value.translation.width / canvasSize.width
                overlayOffsetY += value.translation.height / canvasSize.height
            }
    }

    // MARK: - Helpers

    private func resetPositions() {
        overlayOffsetX = 0
        overlayOffsetY = 0
    }
}
