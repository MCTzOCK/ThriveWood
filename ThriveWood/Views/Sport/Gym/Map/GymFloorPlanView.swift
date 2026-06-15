//
//  GymFloorPlanView.swift
//  ThriveWood
//


import SwiftUI

struct GymFloorPlanView: View {
    @Environment(AppEnvironment.self) private var env
    @Bindable var gym: Gym
    var isReadOnly: Bool = false
    var highlightEquipmentID: UUID? = nil
    var nextEquipmentID: UUID? = nil

    @State private var selectedFloor: Int = 0
    @State private var mode: FloorPlanMode = .navigate

    @State private var wallStart: CGPoint? = nil
    @State private var wallPreview: CGPoint? = nil

    @State private var zoneCreationStart: CGPoint? = nil
    @State private var zoneCreationCurrent: CGPoint? = nil
    @State private var selectedZoneType: GymZone = .other

    @GestureState private var zoneDragOffset: CGSize = .zero
    @GestureState private var equipmentDragOffset: CGSize = .zero
    @State private var draggingZoneID: UUID? = nil
    @State private var draggingEquipmentID: UUID? = nil

    @State private var tappedZone: FloorZone? = nil
    @State private var showingZoneActions = false
    @State private var showingZoneRename = false
    @State private var zoneRenameText = ""
    @State private var showingZoneRecolor = false
    @State private var zoneRecolorSelection: GymZone = .other

    @State private var tappedEquipment: GymEquipment? = nil
    @State private var showingEquipmentActions = false
    @State private var editingEquipment: GymEquipment? = nil
    @State private var showingAddEquipment = false

    @State private var showingFloorRename = false
    @State private var floorRenameText = ""
    @State private var editingFloorIndex: Int? = nil
    @State private var floorToDeleteIndex: Int? = nil

    @State private var deleteTarget: DeleteTarget? = nil
    @State private var showingDeleteConfirm = false

    @State private var errors = ErrorState()

    enum FloorPlanMode: String, CaseIterable {
        case navigate = "Navigieren"
        case wall = "Wände"
        case zone = "Zonen"
        case equipment = "Geräte"
    }

    enum DeleteTarget {
        case wall(WallSegment)
    }

    private let baseCanvasSize: CGFloat = 600

    private var canvasSize: CGFloat {
        let padding: CGFloat = 80
        var maxExtent: CGFloat = baseCanvasSize
        for zone in currentZones {
            let right = (zone.x + zone.width) * baseCanvasSize
            let bottom = (zone.y + zone.height) * baseCanvasSize
            maxExtent = max(maxExtent, right + padding, bottom + padding)
        }
        for wall in currentWalls {
            let wallMax = max(wall.startX, wall.endX, wall.startY, wall.endY) * baseCanvasSize
            maxExtent = max(maxExtent, wallMax + padding)
        }
        for eq in currentEquipment {
            let eqPos = max(eq.positionX, eq.positionY) * baseCanvasSize
            maxExtent = max(maxExtent, eqPos + padding)
        }
        return maxExtent
    }

    var body: some View {
        VStack(spacing: 0) {
            floorSelector
            canvasContent
            if !isReadOnly { modeBar }
        }
        .background(Color(.systemBackground))
        .confirmationDialog("Gerät", isPresented: $showingEquipmentActions, titleVisibility: .visible) {
            Button("Bearbeiten") {
                if let eq = tappedEquipment { editingEquipment = eq }
            }
            Button("Duplizieren") {
                if let eq = tappedEquipment {
                    do {
                        let dup = try env.gymService.addEquipment(
                            name: eq.name,
                            type: eq.equipmentType,
                            floorIndex: eq.floorIndex,
                            zone: eq.zone,
                            icon: eq.iconSystemName,
                            to: gym
                        )
                        for assignment in eq.exerciseAssignments.sorted(by: { $0.order < $1.order }) {
                            if let ex = assignment.exercise {
                                try env.gymService.assignExercise(ex, to: dup, in: gym)
                            }
                        }
                        Haptics.success()
                    } catch { errors.show(error) }
                }
            }
            Button("Löschen", role: .destructive) {
                if let eq = tappedEquipment {
                    do {
                        try env.gymService.removeEquipment(eq, from: gym)
                        Haptics.impact()
                    } catch { errors.show(error) }
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showingAddEquipment) {
            EquipmentCatalogSheet(gym: gym)
        }
        .sheet(item: $editingEquipment) { eq in
            EquipmentEditorSheet(gym: gym, editing: eq)
        }
        .confirmationDialog("Zone", isPresented: $showingZoneActions, titleVisibility: .visible) {
            Button("Umbenennen") {
                zoneRenameText = tappedZone?.name ?? ""
                showingZoneRename = true
            }
            Button("Farbe ändern") {
                zoneRecolorSelection = GymZone(rawValue: tappedZone?.name ?? "") ?? .other
                showingZoneRecolor = true
            }
            Button("Löschen", role: .destructive) {
                if let z = tappedZone, let plan = currentPlan {
                    try? env.gymService.removeZone(z, from: plan, in: gym)
                    Haptics.impact()
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert("Zone umbenennen", isPresented: $showingZoneRename) {
            TextField("Name", text: $zoneRenameText)
            Button("Abbrechen", role: .cancel) {}
            Button("Speichern") {
                if let z = tappedZone, !zoneRenameText.trimmingCharacters(in: .whitespaces).isEmpty {
                    z.name = zoneRenameText.trimmingCharacters(in: .whitespaces)
                    try? env.gymService.updateGym(gym)
                }
            }
        }
        .confirmationDialog("Zonenfarbe", isPresented: $showingZoneRecolor, titleVisibility: .visible) {
            ForEach(GymZone.allCases) { z in
                Button {
                    if let tz = tappedZone {
                        tz.colorRaw = z.colorHex
                        try? env.gymService.updateGym(gym)
                    }
                } label: {
                    Label(z.label, systemImage: z.icon)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert("Stockwerk umbenennen", isPresented: $showingFloorRename) {
            TextField("Name", text: $floorRenameText)
            Button("Abbrechen", role: .cancel) {}
            Button("Speichern") {
                guard let idx = editingFloorIndex, idx < gym.sortedFloorPlans.count else { return }
                let plan = gym.sortedFloorPlans[idx]
                plan.floorName = floorRenameText.trimmingCharacters(in: .whitespaces)
                try? env.gymService.updateGym(gym)
            }
        }
        .alert("Stockwerk löschen?", isPresented: .init(
            get: { floorToDeleteIndex != nil },
            set: { if !$0 { floorToDeleteIndex = nil } }
        )) {
            Button("Löschen", role: .destructive) {
                guard let idx = floorToDeleteIndex, idx < gym.sortedFloorPlans.count else { return }
                let plan = gym.sortedFloorPlans[idx]
                do {
                    try env.gymService.removeFloorPlan(plan, from: gym)
                    selectedFloor = max(0, min(selectedFloor, gym.floorPlans.count - 1))
                    Haptics.impact()
                } catch { errors.show(error) }
                floorToDeleteIndex = nil
            }
            Button("Abbrechen", role: .cancel) { floorToDeleteIndex = nil }
        } message: {
            Text("Alle Zonen und Geräte auf diesem Stockwerk werden entfernt.")
        }
        .alert("Löschen?", isPresented: $showingDeleteConfirm) {
            Button("Löschen", role: .destructive) { performDelete() }
            Button("Abbrechen", role: .cancel) {}
        }
        .errorAlert(errors)
        .onAppear { ensureFloorPlanExists() }
    }

    // MARK: - Floor Selector

    private var floorSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(gym.sortedFloorPlans.enumerated()), id: \.offset) { idx, plan in
                    Button { Haptics.selection(); selectedFloor = idx } label: {
                        Text(plan.floorName)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(selectedFloor == idx ? Color.accentColor : Color(.secondarySystemGroupedBackground)))
                            .foregroundStyle(selectedFloor == idx ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if !isReadOnly {
                            Button {
                                editingFloorIndex = idx
                                floorRenameText = plan.floorName
                                showingFloorRename = true
                            } label: {
                                Label("Umbenennen", systemImage: "pencil")
                            }
                            if gym.floorPlans.count > 1 {
                                Button(role: .destructive) {
                                    floorToDeleteIndex = idx
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                if !isReadOnly {
                    Button {
                        let name = gym.floorPlans.isEmpty ? "EG" : "Stock \(gym.floorPlans.count + 1)"
                        do {
                            _ = try env.gymService.addFloorPlan(to: gym, name: name)
                            selectedFloor = gym.floorPlans.count - 1
                            Haptics.success()
                        } catch { errors.show(error) }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
        }
    }

    // MARK: - Canvas

    private var canvasContent: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    canvasBackground

                    zonesLayer

                    wallsLayer

                    equipmentLayer

                    if mode == .zone, let start = zoneCreationStart, let current = zoneCreationCurrent {
                        let r = pixelRect(from: start, to: current)
                        if r.width > 10 && r.height > 10 {
                            RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .fill(Color.accentColor.opacity(0.08))
                                .frame(width: r.width, height: r.height)
                                .position(x: r.midX, y: r.midY)
                        }
                    }

                    if mode == .wall, let start = wallStart, let preview = wallPreview {
                        WallLineView(from: start, to: preview, color: .accentColor)
                    }
                }
                .frame(width: canvasSize, height: canvasSize)
                .contentShape(Rectangle())
                .gesture(canvasDragGesture, including: mode == .navigate ? .subviews : .gesture)
            }
            .scrollDisabled(mode != .navigate)
        }
    }

    @ViewBuilder
    private var canvasBackground: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .frame(width: canvasSize, height: canvasSize)
            .overlay(
                Canvas { ctx, size in
                    let step: CGFloat = 30
                    var x: CGFloat = step
                    while x < size.width {
                        ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) },
                                   with: .color(Color(.tertiarySystemFill)), lineWidth: 0.5)
                        x += step
                    }
                    var y: CGFloat = step
                    while y < size.height {
                        ctx.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) },
                                   with: .color(Color(.tertiarySystemFill)), lineWidth: 0.5)
                        y += step
                    }
                }
            )
    }

    // MARK: - Zones Layer

    private var zonesLayer: some View {
        ForEach(currentZones) { zone in
            let rect = CGRect(
                x: zone.x * canvasSize,
                y: zone.y * canvasSize,
                width: zone.width * canvasSize,
                height: zone.height * canvasSize
            )
            let isDragging = draggingZoneID == zone.id
            let zColor = Color(hex: zone.colorRaw) ?? .gray

            RoundedRectangle(cornerRadius: Theme.Radius.s)
                .fill(zColor.opacity(isDragging ? 0.25 : 0.15))
                .frame(width: rect.width, height: rect.height)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.s)
                        .strokeBorder(zColor, style: StrokeStyle(lineWidth: 2, dash: [6]))
                )
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: zoneIcon(for: zone.name))
                            .font(.system(size: 10))
                        Text(zone.name)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(zColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.regularMaterial))
                    .padding(6)
                }
                .overlay(alignment: .bottomTrailing) {
                    if mode == .zone && !isReadOnly {
                        resizeHandle(color: zColor) { dx, dy in
                            let newW = max(0.08, zone.width + dx / canvasSize)
                            let newH = max(0.08, zone.height + dy / canvasSize)
                            zone.width = min(1.0 - zone.x, newW)
                            zone.height = min(1.0 - zone.y, newH)
                        } onEnded: {
                            try? env.gymService.updateGym(gym)
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if mode == .zone && !isReadOnly {
                        resizeHandle(color: zColor) { dx, dy in
                            let newX = max(0, zone.x + dx / canvasSize)
                            let newY = max(0, zone.y + dy / canvasSize)
                            let dw = zone.x - newX
                            let dh = zone.y - newY
                            zone.x = newX
                            zone.y = newY
                            zone.width = max(0.08, zone.width + dw)
                            zone.height = max(0.08, zone.height + dh)
                        } onEnded: {
                            try? env.gymService.updateGym(gym)
                        }
                    }
                }
                .position(
                    x: rect.midX + (isDragging ? zoneDragOffset.width : 0),
                    y: rect.midY + (isDragging ? zoneDragOffset.height : 0)
                )
                .onTapGesture {
                    if isReadOnly { return }
                    if mode == .zone {
                        tappedZone = zone
                        showingZoneActions = true
                    }
                }
                .gesture(mode == .zone && !isReadOnly ? zoneMoveGesture(zone) : nil)
        }
    }

    @ViewBuilder
    private func resizeHandle(color: Color, onDrag: @escaping (CGFloat, CGFloat) -> Void, onEnded: @escaping () -> Void) -> some View {
        let size: CGFloat = 22
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 3)
            .padding(4)
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        onDrag(value.translation.width, value.translation.height)
                    }
                    .onEnded { _ in onEnded() }
            )
    }

    // MARK: - Walls Layer

    private var wallsLayer: some View {
        ForEach(currentWalls) { wall in
            let from = CGPoint(x: wall.startX * canvasSize, y: wall.startY * canvasSize)
            let to = CGPoint(x: wall.endX * canvasSize, y: wall.endY * canvasSize)
            WallLineView(from: from, to: to, color: .primary.opacity(0.6))
                .contentShape(
                    Path { path in
                        let expand: CGFloat = 18
                        let dx = to.x - from.x
                        let dy = to.y - from.y
                        let len = max(1, hypot(dx, dy))
                        let nx = -dy / len * expand
                        let ny = dx / len * expand
                        path.move(to: CGPoint(x: from.x + nx, y: from.y + ny))
                        path.addLine(to: CGPoint(x: to.x + nx, y: to.y + ny))
                        path.addLine(to: CGPoint(x: to.x - nx, y: to.y - ny))
                        path.addLine(to: CGPoint(x: from.x - nx, y: from.y - ny))
                        path.closeSubpath()
                    }
                )
                .onTapGesture {
                    if !isReadOnly && mode == .wall {
                        deleteTarget = .wall(wall)
                        showingDeleteConfirm = true
                    }
                }
        }
    }

    // MARK: - Equipment Layer

    private var equipmentLayer: some View {
        ForEach(currentEquipment) { eq in
            let isHighlighted = eq.id == highlightEquipmentID
            let isNext = eq.id == nextEquipmentID
            let isDragging = draggingEquipmentID == eq.id
            EquipmentPin(
                equipment: eq,
                isHighlighted: isHighlighted,
                isNext: isNext,
                canvasSize: canvasSize,
                dragOffset: isDragging ? equipmentDragOffset : .zero
            )
            .onTapGesture {
                if isReadOnly { return }
                tappedEquipment = eq
                showingEquipmentActions = true
            }
            .gesture(mode == .equipment && !isReadOnly ? equipmentMoveGesture(eq) : nil)
        }
    }

    // MARK: - Gestures

    private var canvasDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                switch mode {
                case .navigate: break
                case .wall:
                    if wallStart == nil {
                        wallStart = snapToGrid(value.startLocation)
                    }
                    wallPreview = snapToGrid(value.location)
                case .zone:
                    if zoneCreationStart == nil {
                        zoneCreationStart = value.startLocation
                    }
                    zoneCreationCurrent = value.location
                case .equipment: break
                }
            }
            .onEnded { value in
                switch mode {
                case .wall:
                    if let start = wallStart, let end = wallPreview {
                        let dist = hypot(end.x - start.x, end.y - start.y)
                        if dist > 20 {
                            do {
                                _ = try env.gymService.addWall(
                                    startX: start.x / canvasSize, startY: start.y / canvasSize,
                                    endX: end.x / canvasSize, endY: end.y / canvasSize,
                                    floorIndex: selectedFloor, to: gym
                                )
                                Haptics.success()
                            } catch { errors.show(error) }
                        }
                    }
                    wallStart = nil
                    wallPreview = nil
                case .zone:
                    if let start = zoneCreationStart, let current = zoneCreationCurrent {
                        let nr = normalizedRect(from: start, to: current)
                        if nr.width > 0.04 && nr.height > 0.04 {
                            createZone(in: nr)
                        }
                    }
                    zoneCreationStart = nil
                    zoneCreationCurrent = nil
                default: break
                }
            }
    }

    private func zoneMoveGesture(_ zone: FloorZone) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if draggingZoneID != zone.id {
                    draggingZoneID = zone.id
                }
            }
            .updating($zoneDragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let dx = value.translation.width / canvasSize
                let dy = value.translation.height / canvasSize
                zone.x = max(0, min(1 - zone.width, zone.x + dx))
                zone.y = max(0, min(1 - zone.height, zone.y + dy))
                try? env.gymService.updateGym(gym)
                draggingZoneID = nil
            }
    }

    private func equipmentMoveGesture(_ eq: GymEquipment) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if draggingEquipmentID != eq.id {
                    draggingEquipmentID = eq.id
                }
            }
            .updating($equipmentDragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let newX = max(0, min(1, eq.positionX + value.translation.width / canvasSize))
                let newY = max(0, min(1, eq.positionY + value.translation.height / canvasSize))
                eq.positionX = newX
                eq.positionY = newY
                eq.zoneRaw = zoneContainingPoint(x: newX, y: newY)?.rawValue
                do {
                    try env.gymService.saveEquipmentPosition(eq, x: newX, y: newY, in: gym)
                } catch { errors.show(error) }
                draggingEquipmentID = nil
            }
    }

    private func zoneContainingPoint(x: Double, y: Double) -> GymZone? {
        guard let plan = currentPlan else { return nil }
        for zone in plan.zones {
            if x >= zone.x && x <= zone.x + zone.width &&
               y >= zone.y && y <= zone.y + zone.height {
                return GymZone(rawValue: zone.name) ?? .other
            }
        }
        return nil
    }

    // MARK: - Mode Bar

    private var modeBar: some View {
        VStack(spacing: Theme.Spacing.s) {
            if mode == .wall {
                Text("Wand ziehen: Vom Start- zum Endpunkt wischen. Tap auf Wand zum Löschen.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if mode == .zone {
                Text("Zone aufziehen, ziehen zum Verschieben, Ecken zum Resizen, Tap zum Bearbeiten.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if mode == .equipment {
                Text("Gerät ziehen zum Verschieben, antippen zum Bearbeiten.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if mode == .zone {
                zoneTypePicker
            }

            HStack(spacing: 0) {
                ForEach(FloorPlanMode.allCases, id: \.self) { m in
                    Button {
                        Haptics.selection()
                        mode = m
                        wallStart = nil
                        wallPreview = nil
                        zoneCreationStart = nil
                        zoneCreationCurrent = nil
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: modeIcon(m))
                                .font(.body)
                            Text(m.rawValue)
                                .font(.caption2.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == m ? Color.accentColor.opacity(0.15) : Color.clear)
                        .foregroundStyle(mode == m ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
            .padding(.horizontal, Theme.Spacing.l)

            if mode == .equipment {
                Button {
                    showingAddEquipment = true
                } label: {
                    Label("Gerät hinzufügen", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, Theme.Spacing.l)
            }
        }
        .padding(.vertical, Theme.Spacing.s)
        .background(Color(.systemBackground))
    }

    private var zoneTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(GymZone.allCases) { z in
                    Button {
                        selectedZoneType = z
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: z.icon).font(.system(size: 10))
                            Text(z.label).font(.caption2.weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(
                            selectedZoneType == z
                                ? (Color(hex: z.colorHex) ?? .accentColor)
                                : Color(.tertiarySystemFill)
                        ))
                        .foregroundStyle(selectedZoneType == z ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    // MARK: - Helpers

    private var currentPlan: FloorPlan? {
        let plans = gym.sortedFloorPlans
        guard selectedFloor < plans.count else { return nil }
        return plans[selectedFloor]
    }

    private var currentWalls: [WallSegment] {
        env.gymService.walls(onFloor: selectedFloor, in: gym)
    }

    private var currentZones: [FloorZone] {
        currentPlan?.sortedZones ?? []
    }

    private var currentEquipment: [GymEquipment] {
        env.gymService.equipment(onFloor: selectedFloor, in: gym)
    }

    private func snapToGrid(_ point: CGPoint) -> CGPoint {
        let step: CGFloat = 15
        return CGPoint(
            x: round(point.x / step) * step,
            y: round(point.y / step) * step
        )
    }

    private func pixelRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }

    private func normalizedRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        let px = pixelRect(from: p1, to: p2)
        return CGRect(
            x: px.origin.x / canvasSize,
            y: px.origin.y / canvasSize,
            width: px.width / canvasSize,
            height: px.height / canvasSize
        )
    }

    private func createZone(in rect: CGRect) {
        guard let plan = currentPlan else { return }
        do {
            _ = try env.gymService.addZone(
                name: selectedZoneType.label,
                color: selectedZoneType.colorHex,
                x: rect.minX, y: rect.minY,
                width: rect.width, height: rect.height,
                to: plan, in: gym
            )
            Haptics.success()
        } catch { errors.show(error) }
    }

    private func modeIcon(_ m: FloorPlanMode) -> String {
        switch m {
        case .navigate: "hand.draw"
        case .wall: "line.3.horizontal"
        case .zone: "rectangle.3.group"
        case .equipment: "dumbbell.fill"
        }
    }

    private func zoneIcon(for name: String) -> String {
        GymZone(rawValue: name)?.icon ?? "rectangle.3.group"
    }

    private func ensureFloorPlanExists() {
        if gym.floorPlans.isEmpty && !isReadOnly {
            do {
                _ = try env.gymService.addFloorPlan(to: gym, name: "EG")
            } catch { errors.show(error) }
        }
    }

    private func performDelete() {
        guard let target = deleteTarget else { return }
        do {
            switch target {
            case .wall(let w): try env.gymService.removeWall(w, from: gym)
            }
            Haptics.impact()
        } catch { errors.show(error) }
        deleteTarget = nil
    }
}


// MARK: - Wall Line View

struct WallLineView: View {
    let from: CGPoint
    let to: CGPoint
    var color: Color = .primary

    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))

        Circle().fill(color).frame(width: 8, height: 8).position(from)
        Circle().fill(color).frame(width: 8, height: 8).position(to)
    }
}


// MARK: - Equipment Pin

struct EquipmentPin: View {
    let equipment: GymEquipment
    var isHighlighted: Bool = false
    var isNext: Bool = false
    var canvasSize: CGFloat = 600
    var dragOffset: CGSize = .zero

    private var pinColor: Color {
        if isHighlighted { return .accentColor }
        if isNext { return .orange }
        return equipmentColor
    }

    private var equipmentColor: Color {
        switch equipment.equipmentType {
        case .bench, .squatRack, .powerRack: .red
        case .cableTower: .blue
        case .dumbbellRack: .orange
        case .cardioMachine: .green
        case .matArea, .pullUpBar: .purple
        default: .gray
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: isHighlighted ? 44 : 36, height: isHighlighted ? 44 : 36)
                    .shadow(color: .black.opacity(0.25), radius: isHighlighted ? 6 : 3)
                Image(systemName: equipment.iconSystemName)
                    .font(isHighlighted ? .body.weight(.bold) : .callout.weight(.semibold))
                    .foregroundStyle(.white)

                if isHighlighted {
                    Circle()
                        .strokeBorder(pinColor.opacity(0.4), lineWidth: 3)
                        .frame(width: 56, height: 56)
                }
            }
            .frame(width: 56, height: 56)

            Text(equipment.name)
                .font(.system(size: isHighlighted ? 11 : 9, weight: .bold))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Group {
                        if isHighlighted {
                            Capsule().fill(pinColor)
                        } else {
                            Capsule().fill(.regularMaterial)
                        }
                    }
                )
                .foregroundStyle(isHighlighted ? .white : .primary)

            if isHighlighted {
                Text("Hier")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(pinColor))
            } else if isNext {
                Text("Nächste")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.orange))
            }
        }
        .position(
            x: equipment.positionX * canvasSize + dragOffset.width,
            y: equipment.positionY * canvasSize + dragOffset.height
        )
    }
}
