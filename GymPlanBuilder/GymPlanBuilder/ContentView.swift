//
//  ContentView.swift
//  GymPlanBuilder
//


import SwiftUI

struct ContentView: View {
    @Binding var plan: GymPlanJSON
    @State private var selectedFloor: Int = 0
    @State private var mode: EditMode = .navigate

    @State private var zoomScale: CGFloat = 1.0
    @State private var zoomScaleAtStart: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var panAtStart: CGSize = .zero

    @State private var dragOffset: CGSize = .zero
    @State private var draggingZoneIdx: Int? = nil
    @State private var draggingEqIdx: Int? = nil

    @State private var wallStart: CGPoint? = nil
    @State private var wallPreview: CGPoint? = nil
    @State private var zoneCreationStart: CGPoint? = nil
    @State private var zoneCreationCurrent: CGPoint? = nil

    @State private var selectedZoneIdx: Int? = nil
    @State private var selectedEqIdx: Int? = nil

    @State private var editingZone: ZoneJSON? = nil
    @State private var editingEq: EquipmentJSON? = nil

    private enum EditMode: String, CaseIterable {
        case navigate = "Navigieren"
        case zone = "Zonen"
        case equipment = "Geräte"
        case wall = "Wände"
    }

    private let baseCanvasSize: CGFloat = 1200
    private let gridSize: CGFloat = 30

    private var canvasSize: CGFloat {
        var s = baseCanvasSize
        let floor = currentFloor
        for zone in floor.zones {
            let right = (zone.x + zone.width) * baseCanvasSize
            let bottom = (zone.y + zone.height) * baseCanvasSize
            s = max(s, right + 80, bottom + 80)
        }
        for wall in plan.walls where wall.floorIndex == selectedFloor {
            s = max(s, max(wall.startX, wall.endX, wall.startY, wall.endY) * baseCanvasSize + 80)
        }
        for eq in plan.equipment where eq.floorIndex == selectedFloor {
            s = max(s, max(eq.positionX, eq.positionY) * baseCanvasSize + 80)
        }
        return s
    }

    private var currentFloor: FloorPlanJSON {
        plan.floors.first { $0.floorIndex == selectedFloor } ?? FloorPlanJSON()
    }

    private var currentFloorIdx: Int {
        plan.floors.firstIndex(where: { $0.floorIndex == selectedFloor }) ?? 0
    }

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 260, maxWidth: 340)

            VStack(spacing: 0) {
                toolbar
                Divider()
                canvasScroller
            }
        }
        .sheet(item: $editingZone) { zone in
            ZoneEditorSheet(plan: $plan, floorIdx: currentFloorIdx, zone: zone)
        }
        .sheet(item: $editingEq) { eq in
            EquipmentEditorSheet(plan: $plan, equipment: eq)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List {
            Section("Gym") {
                TextField("Name", text: $plan.name)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Stockwerke") {
                ForEach(plan.floors.indices, id: \.self) { i in
                    HStack {
                        Text(plan.floors[i].floorName)
                        Spacer()
                        Text("\(plan.floors[i].zones.count) Zonen")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .contextMenu {
                        Button("Umbenennen") {
                            let idx = i
                            let alert = NSAlert()
                            alert.messageText = "Stockwerk umbenennen"
                            let tf = NSTextField(string: plan.floors[idx].floorName)
                            tf.frame = NSRect(x: 0, y: 0, width: 200, height: 24)
                            alert.accessoryView = tf
                            alert.addButton(withTitle: "OK")
                            alert.addButton(withTitle: "Abbrechen")
                            if alert.runModal() == .alertFirstButtonReturn {
                                plan.floors[idx].floorName = tf.stringValue
                            }
                        }
                        if plan.floors.count > 1 {
                            Button("Löschen", role: .destructive) {
                                plan.floors.remove(at: i)
                                plan.equipment.removeAll { $0.floorIndex == plan.floors[i].floorIndex }
                                plan.walls.removeAll { $0.floorIndex == plan.floors[i].floorIndex }
                                if selectedFloor >= plan.floors.count { selectedFloor = 0 }
                            }
                        }
                    }
                }
                Button("+ Stockwerk") {
                    plan.floors.append(FloorPlanJSON(floorIndex: plan.floors.count, floorName: "\(plan.floors.count + 1). OG"))
                }
            }

            Section("Zonen (\(currentFloor.zones.count))") {
                ForEach(currentFloor.zones.indices, id: \.self) { i in
                    HStack {
                        Circle().fill(Color(hex: currentFloor.zones[i].colorHex)).frame(width: 10, height: 10)
                        Text(currentFloor.zones[i].name)
                        Spacer()
                        if mode == .zone {
                            Button {
                                editingZone = currentFloor.zones[i]
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        Button(role: .destructive) {
                            plan.floors[currentFloorIdx].zones.remove(at: i)
                            if selectedZoneIdx == i { selectedZoneIdx = nil }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section("Geräte (\(plan.equipment.filter { $0.floorIndex == selectedFloor }.count))") {
                ForEach(plan.equipment.indices, id: \.self) { i in
                    HStack {
                        Image(systemName: plan.equipment[i].iconSystemName)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(plan.equipment[i].name)
                        Spacer()
                        if plan.equipment[i].floorIndex == selectedFloor {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                        }
                        if mode == .equipment {
                            Button {
                                editingEq = plan.equipment[i]
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        Button(role: .destructive) {
                            plan.equipment.remove(at: i)
                            if selectedEqIdx == i { selectedEqIdx = nil }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Button("+ Gerät hinzufügen") {
                    let newEq = EquipmentJSON(floorIndex: selectedFloor)
                    plan.equipment.append(newEq)
                    editingEq = newEq
                }
            }

            Section("Wände (\(plan.walls.filter { $0.floorIndex == selectedFloor }.count))") {
                ForEach(Array(plan.walls.enumerated()), id: \.offset) { i, wall in
                    if wall.floorIndex == selectedFloor {
                        HStack {
                            Image(systemName: "line.diagonal")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text("Wand \(i + 1)")
                            Spacer()
                            Button(role: .destructive) {
                                plan.walls.remove(at: i)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            Picker("Stockwerk", selection: $selectedFloor) {
                ForEach(plan.floors, id: \.floorIndex) { f in
                    Text(f.floorName).tag(f.floorIndex)
                }
            }
            .frame(width: 120)

            Picker("Modus", selection: $mode) {
                ForEach(EditMode.allCases, id: \.self) { m in
                    Label(m.rawValue, systemImage: modeIcon(m)).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)

            Spacer()

            Text("\(Int(zoomScale * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            Button { zoomScale = max(0.2, zoomScale - 0.25); zoomScaleAtStart = zoomScale } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("-", modifiers: [.command])

            Button { zoomScale = min(4.0, zoomScale + 0.25); zoomScaleAtStart = zoomScale } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("+", modifiers: [.command])

            Button { zoomScale = 1.0; zoomScaleAtStart = 1.0; panOffset = .zero; panAtStart = .zero } label: {
                Image(systemName: "1.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("0", modifiers: [.command])

            Button { mode = .navigate } label: {
                Image(systemName: "hand.draw")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("1", modifiers: [])
            .help("Navigieren (1)")

            Button { mode = .zone } label: {
                Image(systemName: "rectangle.on.rectangle.angled")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("2", modifiers: [])
            .help("Zonen (2)")

            Button { mode = .equipment } label: {
                Image(systemName: "dumbbell.fill")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("3", modifiers: [])
            .help("Geräte (3)")

            Button { mode = .wall } label: {
                Image(systemName: "line.diagonal")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("4", modifiers: [])
            .help("Wände (4)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func modeIcon(_ m: EditMode) -> String {
        switch m {
        case .navigate: "hand.draw"
        case .zone: "rectangle.on.rectangle.angled"
        case .equipment: "dumbbell.fill"
        case .wall: "line.diagonal"
        }
    }

    // MARK: - Canvas (ScrollView + zoom/pan)

    private var canvasScroller: some View {
        ScrollView([.horizontal, .vertical]) {
            canvasInternal
                .scaleEffect(zoomScale, anchor: .topLeading)
                .frame(width: canvasSize * zoomScale, height: canvasSize * zoomScale, alignment: .topLeading)
        }
        .clipped()
        .gesture(scrollZoomGesture, including: .subviews)
    }

    private var canvasInternal: some View {
        ZStack(alignment: .topLeading) {
            gridBackground

            zonesLayer

            wallsLayer

            equipmentLayer

            if mode == .zone, let start = zoneCreationStart, let current = zoneCreationCurrent {
                let r = pixelRect(from: start, to: current)
                if r.width > 5 && r.height > 5 {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .fill(Color.accentColor.opacity(0.06))
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                }
            }

            if mode == .wall, let start = wallStart, let preview = wallPreview {
                WallLineView(from: start, to: preview, color: .accentColor)
            }
        }
        .gesture(canvasDragGesture, including: mode == .wall || mode == .zone ? .gesture : .subviews)
    }

    private var gridBackground: some View {
        Canvas { ctx, size in
            let step = gridSize
            var x: CGFloat = step
            while x < size.width {
                ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) },
                           with: .color(Color.gray.opacity(0.15)), lineWidth: 0.5)
                x += step
            }
            var y: CGFloat = step
            while y < size.height {
                ctx.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) },
                           with: .color(Color.gray.opacity(0.15)), lineWidth: 0.5)
                y += step
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    // MARK: - Zones Layer

    private var zonesLayer: some View {
        ForEach(currentFloor.zones.indices, id: \.self) { i in
            let zone = currentFloor.zones[i]
            let rect = CGRect(x: zone.x * canvasSize, y: zone.y * canvasSize, width: zone.width * canvasSize, height: zone.height * canvasSize)
            let isDragging = draggingZoneIdx == i
            let isSelected = selectedZoneIdx == i

            ZoneView(name: zone.name, colorHex: zone.colorHex, isSelected: isSelected || mode == .zone)
                .frame(width: max(1, rect.width), height: max(1, rect.height))
                .offset(isDragging ? dragOffset : .zero)
                .position(x: rect.midX, y: rect.midY)
                .gesture(mode == .zone ? zoneDragGesture(index: i) : nil)
                .contextMenu {
                    Button("Umbenennen / Farbe ändern...") {
                        editingZone = plan.floors[currentFloorIdx].zones[i]
                    }
                    Button("Duplizieren") {
                        let z = plan.floors[currentFloorIdx].zones[i]
                        let dup = ZoneJSON(name: z.name, colorHex: z.colorHex, x: z.x + 0.02, y: z.y + 0.02, width: z.width, height: z.height)
                        plan.floors[currentFloorIdx].zones.append(dup)
                    }
                    Button("Löschen", role: .destructive) {
                        plan.floors[currentFloorIdx].zones.remove(at: i)
                        selectedZoneIdx = nil
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if mode == .zone { ZoneResizeHandle().gesture(zoneResizeGesture(index: i, corner: .bottomTrailing)) }
                }
                .overlay(alignment: .topLeading) {
                    if mode == .zone { ZoneResizeHandle().gesture(zoneResizeGesture(index: i, corner: .topLeading)) }
                }
                .overlay(alignment: .bottomLeading) {
                    if mode == .zone { ZoneResizeHandle().gesture(zoneResizeGesture(index: i, corner: .bottomLeading)) }
                }
                .overlay(alignment: .topTrailing) {
                    if mode == .zone { ZoneResizeHandle().gesture(zoneResizeGesture(index: i, corner: .topTrailing)) }
                }
        }
    }

    // MARK: - Walls Layer

    private var wallsLayer: some View {
        ForEach(Array(plan.walls.enumerated()), id: \.offset) { i, wall in
            if wall.floorIndex == selectedFloor {
                WallLineView(
                    from: CGPoint(x: wall.startX * canvasSize, y: wall.startY * canvasSize),
                    to: CGPoint(x: wall.endX * canvasSize, y: wall.endY * canvasSize),
                    color: .secondary
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if mode == .wall {
                        plan.walls.remove(at: i)
                    }
                }
                .contextMenu {
                    Button("Löschen", role: .destructive) {
                        plan.walls.remove(at: i)
                    }
                }
            }
        }
    }

    // MARK: - Equipment Layer

    private var equipmentLayer: some View {
        ForEach(plan.equipment.indices, id: \.self) { i in
            let eq = plan.equipment[i]
            if eq.floorIndex == selectedFloor {
                let isDragging = draggingEqIdx == i
                EquipmentPinView(name: eq.name, icon: eq.iconSystemName, isSelected: selectedEqIdx == i || mode == .equipment)
                    .offset(isDragging ? dragOffset : .zero)
                    .position(x: eq.positionX * canvasSize, y: eq.positionY * canvasSize)
                    .gesture(mode == .equipment ? eqDragGesture(index: i) : nil)
                    .contextMenu {
                        Button("Bearbeiten...") {
                            editingEq = plan.equipment[i]
                        }
                        Button("Duplizieren") {
                            let eq = plan.equipment[i]
                            let dup = EquipmentJSON(name: eq.name, type: eq.type, iconSystemName: eq.iconSystemName, positionX: min(1, eq.positionX + 0.03), positionY: min(1, eq.positionY + 0.03), floorIndex: eq.floorIndex, zone: eq.zone, exerciseNames: eq.exerciseNames)
                            plan.equipment.append(dup)
                        }
                        Button("Löschen", role: .destructive) {
                            plan.equipment.remove(at: i)
                            selectedEqIdx = nil
                        }
                    }
            }
        }
    }

    // MARK: - Gestures

    private var scrollZoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = min(4.0, max(0.2, zoomScaleAtStart * value.magnification))
                zoomScale = newScale
            }
            .onEnded { _ in
                zoomScaleAtStart = zoomScale
            }
    }

    private var canvasDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let start = canvasPoint(value.startLocation)
                let current = canvasPoint(value.location)
                switch mode {
                case .navigate, .equipment: break
                case .wall:
                    if wallStart == nil { wallStart = snap(start) }
                    wallPreview = snap(current)
                case .zone:
                    if zoneCreationStart == nil { zoneCreationStart = snap(start) }
                    zoneCreationCurrent = snap(current)
                }
            }
            .onEnded { value in
                switch mode {
                case .navigate, .equipment: break
                case .wall:
                    if let start = wallStart, let end = wallPreview, hypot(end.x - start.x, end.y - start.y) > 10 {
                        plan.walls.append(WallJSON(startX: start.x / canvasSize, startY: start.y / canvasSize, endX: end.x / canvasSize, endY: end.y / canvasSize, floorIndex: selectedFloor))
                    }
                    wallStart = nil; wallPreview = nil
                case .zone:
                    if let start = zoneCreationStart, let current = zoneCreationCurrent {
                        let r = normalizedRect(from: start, to: current)
                        if r.width > 0.02 && r.height > 0.02 {
                            let newZone = ZoneJSON(x: r.minX, y: r.minY, width: r.width, height: r.height)
                            plan.floors[currentFloorIdx].zones.append(newZone)
                        }
                    }
                    zoneCreationStart = nil; zoneCreationCurrent = nil
                }
            }
    }

    private func zoneDragGesture(index: Int) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                draggingZoneIdx = index
                dragOffset = value.translation
            }
            .onEnded { value in
                let dx = value.translation.width / canvasSize
                let dy = value.translation.height / canvasSize
                let z = plan.floors[currentFloorIdx].zones[index]
                plan.floors[currentFloorIdx].zones[index].x = snapNorm(max(0, min(1 - z.width, z.x + dx)))
                plan.floors[currentFloorIdx].zones[index].y = snapNorm(max(0, min(1 - z.height, z.y + dy)))
                draggingZoneIdx = nil; dragOffset = .zero
            }
    }

    private enum ResizeCorner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    private func zoneResizeGesture(index: Int, corner: ResizeCorner) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let dz = value.translation.width / canvasSize
                let dv = value.translation.height / canvasSize
                let z = plan.floors[currentFloorIdx].zones[index]
                switch corner {
                case .topLeading:
                    let newX = max(0, z.x + dz)
                    plan.floors[currentFloorIdx].zones[index].width = max(0.05, z.width + (z.x - newX))
                    plan.floors[currentFloorIdx].zones[index].x = newX
                    let newY = max(0, z.y + dv)
                    plan.floors[currentFloorIdx].zones[index].height = max(0.05, z.height + (z.y - newY))
                    plan.floors[currentFloorIdx].zones[index].y = newY
                case .topTrailing:
                    plan.floors[currentFloorIdx].zones[index].width = snapNorm(max(0.05, min(1 - z.x, z.width + dz)))
                    let newY = max(0, z.y + dv)
                    plan.floors[currentFloorIdx].zones[index].height = max(0.05, z.height + (z.y - newY))
                    plan.floors[currentFloorIdx].zones[index].y = newY
                case .bottomLeading:
                    let newX = max(0, z.x + dz)
                    plan.floors[currentFloorIdx].zones[index].width = max(0.05, z.width + (z.x - newX))
                    plan.floors[currentFloorIdx].zones[index].x = newX
                    plan.floors[currentFloorIdx].zones[index].height = snapNorm(max(0.05, min(1 - z.y, z.height + dv)))
                case .bottomTrailing:
                    plan.floors[currentFloorIdx].zones[index].width = snapNorm(max(0.05, min(1 - z.x, z.width + dz)))
                    plan.floors[currentFloorIdx].zones[index].height = snapNorm(max(0.05, min(1 - z.y, z.height + dv)))
                }
            }
    }

    private func eqDragGesture(index: Int) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                draggingEqIdx = index
                dragOffset = value.translation
            }
            .onEnded { value in
                let eq = plan.equipment[index]
                plan.equipment[index].positionX = snapNorm(max(0, min(1, eq.positionX + value.translation.width / canvasSize)))
                plan.equipment[index].positionY = snapNorm(max(0, min(1, eq.positionY + value.translation.height / canvasSize)))
                draggingEqIdx = nil; dragOffset = .zero
            }
    }

    // MARK: - Helpers

    private func canvasPoint(_ gesturePoint: CGPoint) -> CGPoint {
        CGPoint(
            x: (gesturePoint.x - panOffset.width) / zoomScale,
            y: (gesturePoint.y - panOffset.height) / zoomScale
        )
    }

    private func snap(_ point: CGPoint) -> CGPoint {
        CGPoint(x: round(point.x / gridSize) * gridSize, y: round(point.y / gridSize) * gridSize)
    }

    private func snapNorm(_ v: Double) -> Double {
        let step = Double(gridSize) / Double(canvasSize)
        return round(v / step) * step
    }

    private func pixelRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        CGRect(x: min(p1.x, p2.x), y: min(p1.y, p2.y), width: abs(p2.x - p1.x), height: abs(p2.y - p1.y))
    }

    private func normalizedRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        let px = pixelRect(from: p1, to: p2)
        return CGRect(x: px.origin.x / canvasSize, y: px.origin.y / canvasSize, width: px.width / canvasSize, height: px.height / canvasSize)
    }
}

struct ZoneEditorSheet: View {
    @Binding var plan: GymPlanJSON
    let floorIdx: Int
    @State var zone: ZoneJSON
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Zone bearbeiten").font(.headline)

            Form {
                TextField("Name", text: $zone.name)
                    .textFieldStyle(.roundedBorder)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                    ForEach(GymZonePreset.allCases, id: \.self) { preset in
                        Button {
                            zone.name = preset.label
                            zone.colorHex = preset.colorHex
                        } label: {
                            VStack(spacing: 4) {
                                Circle().fill(Color(hex: preset.colorHex))
                                    .frame(width: 22, height: 22)
                                    .overlay(Circle().strokeBorder(zone.colorHex == preset.colorHex ? Color.accentColor : .clear, lineWidth: 2))
                                Text(preset.label).font(.caption2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                LabeledContent("Farbe (Hex)") {
                    TextField("#RRGGBB", text: $zone.colorHex)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                LabeledContent("Größe") {
                    HStack {
                        TextField("X", value: $zone.x, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        TextField("Y", value: $zone.y, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        TextField("W", value: $zone.width, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        TextField("H", value: $zone.height, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }
                }
            }

            HStack {
                Button("Abbrechen") { dismiss() }
                Button("Speichern") {
                    if let idx = plan.floors[floorIdx].zones.firstIndex(where: { $0.name == zone.name && $0.colorHex == zone.colorHex }) {
                        plan.floors[floorIdx].zones[idx] = zone
                    } else {
                        for i in plan.floors[floorIdx].zones.indices {
                            if abs(plan.floors[floorIdx].zones[i].x - zone.x) < 0.001 && abs(plan.floors[floorIdx].zones[i].y - zone.y) < 0.001 {
                                plan.floors[floorIdx].zones[i] = zone
                                break
                            }
                        }
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(zone.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

// MARK: - Equipment Editor Sheet

struct EquipmentEditorSheet: View {
    @Binding var plan: GymPlanJSON
    @State var equipment: EquipmentJSON
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Gerät bearbeiten").font(.headline)

            Form {
                TextField("Name", text: $equipment.name)
                    .textFieldStyle(.roundedBorder)

                Picker("Typ", selection: $equipment.type) {
                    ForEach(EquipmentTypePreset.allCases, id: \.self) { t in
                        Label {
                            Text(t.label)
                        } icon: {
                            Image(systemName: t.icon)
                        }
                        .tag(t.rawValue)
                    }
                }

                Picker("Icon", selection: $equipment.iconSystemName) {
                    ForEach(equipmentIcons, id: \.self) { icon in
                        Label(icon, systemImage: icon).tag(icon)
                    }
                }

                Picker("Stockwerk", selection: $equipment.floorIndex) {
                    ForEach(plan.floors, id: \.floorIndex) { f in
                        Text(f.floorName).tag(f.floorIndex)
                    }
                }

                TextField("Zone", text: Binding(
                    get: { equipment.zone ?? "" },
                    set: { equipment.zone = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)

                LabeledContent("Übungen") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(equipment.exerciseNames, id: \.self) { name in
                            HStack {
                                Text(name).font(.caption)
                                Spacer()
                                Button(role: .destructive) {
                                    equipment.exerciseNames.removeAll { $0 == name }
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        HStack {
                            TextField("Übung hinzufügen", text: $newExercise)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { addExercise() }
                            Button("+") { addExercise() }
                                .buttonStyle(.borderless)
                        }
                    }
                }
            }

            HStack {
                Button("Abbrechen") { dismiss() }
                Button("Speichern") {
                    if let idx = plan.equipment.firstIndex(where: { $0.iconSystemName == equipment.iconSystemName && abs($0.positionX - equipment.positionX) < 0.001 && abs($0.positionY - equipment.positionY) < 0.001 }) {
                        plan.equipment[idx] = equipment
                    } else {
                        for i in plan.equipment.indices {
                            if plan.equipment[i].name == equipment.name && plan.equipment[i].floorIndex == equipment.floorIndex {
                                plan.equipment[i] = equipment
                                break
                            }
                        }
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(equipment.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    @State private var newExercise: String = ""

    private func addExercise() {
        let name = newExercise.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        equipment.exerciseNames.append(name)
        newExercise = ""
    }
}

// MARK: - Constants

private let equipmentIcons = [
    "dumbbell.fill", "barbell.fill", "figure.strengthtraining.traditional",
    "heart.fill", "figure.run", "figure.walk",
    "bed.double.fill", "arrow.up.and.down.text.horizontal",
    "cable.fill", "scalemass.fill", "rectangle.fill",
    "arrow.up.to.line", "circle.fill", "star.fill",
    "bolt.fill", "flame.fill", "drop.fill",
    "figure.core.training", "figure.flexibility"
]

// MARK: - Subviews

struct ZoneView: View {
    let name: String
    let colorHex: String
    let isSelected: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(hex: colorHex).opacity(0.15))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(hex: colorHex).opacity(isSelected ? 0.9 : 0.4), lineWidth: isSelected ? 2.5 : 1.5))
            .overlay(alignment: .topLeading) {
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: colorHex))
                    .padding(6)
            }
    }
}

struct ZoneResizeHandle: View {
    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(width: 16, height: 16)
            .background(Circle().fill(.background))
            .overlay(Circle().strokeBorder(.secondary.opacity(0.5), lineWidth: 1))
    }
}

struct EquipmentPinView: View {
    let name: String
    let icon: String
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(isSelected ? Color.accentColor : Color(hex: "#555555")))
            Text(name)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 50)
        }
    }
}

struct WallLineView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    var body: some View {
        Path { p in p.move(to: from); p.addLine(to: to) }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Path { p in
                p.move(to: from)
                p.addLine(to: to)
            }.strokedPath(StrokeStyle(lineWidth: 14)))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
