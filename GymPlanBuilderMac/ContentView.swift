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
    @State private var editingZoneFloorIdx: Int = 0
    @State private var editingEq: EquipmentJSON? = nil

    @State private var resizeStartZone: CGRect = .zero
    @State private var isResizing: Bool = false

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
        .sheet(item: $editingZone) { _ in
            ZoneEditorSheet(plan: $plan, floorIdx: editingZoneFloorIdx, zone: editingZone ?? ZoneJSON())
        }
        .sheet(item: $editingEq) { _ in
            EquipmentEditorSheet(plan: $plan, equipment: editingEq ?? EquipmentJSON())
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
                                editingZoneFloorIdx = currentFloorIdx
                                editingZone = plan.floors[currentFloorIdx].zones[i]
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
                                if i < plan.walls.count && wall.startX == plan.walls[i].startX && wall.startY == plan.walls[i].startY {
                                    plan.walls.remove(at: i)
                                }
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

            Button { zoomScale = 1.0; zoomScaleAtStart = 1.0 } label: {
                Image(systemName: "1.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("0", modifiers: [.command])

            Button { mode = .navigate } label: { Image(systemName: "hand.draw") }
                .buttonStyle(.borderless)
                .keyboardShortcut("1", modifiers: [])
            Button { mode = .zone } label: { Image(systemName: "rectangle.on.rectangle.angled") }
                .buttonStyle(.borderless)
                .keyboardShortcut("2", modifiers: [])
            Button { mode = .equipment } label: { Image(systemName: "dumbbell.fill") }
                .buttonStyle(.borderless)
                .keyboardShortcut("3", modifiers: [])
            Button { mode = .wall } label: { Image(systemName: "line.diagonal") }
                .buttonStyle(.borderless)
                .keyboardShortcut("4", modifiers: [])
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

    // MARK: - Canvas

    private var sc: CGFloat { canvasSize * zoomScale }

    private var canvasScroller: some View {
        ScrollView([.horizontal, .vertical]) {
            canvasInternal
                .frame(width: sc, height: sc, alignment: .topLeading)
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
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2 * zoomScale, dash: [6 * zoomScale]))
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
            let step = gridSize * zoomScale
            var x = step
            while x < size.width {
                ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) },
                           with: .color(Color.gray.opacity(0.15)), lineWidth: 0.5)
                x += step
            }
            var y = step
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
            let rect = CGRect(x: zone.x * sc, y: zone.y * sc, width: zone.width * sc, height: zone.height * sc)
            let isDragging = draggingZoneIdx == i
            let isSelected = selectedZoneIdx == i

            ZoneView(name: zone.name, colorHex: zone.colorHex, isSelected: isSelected || mode == .zone)
                .frame(width: max(1, rect.width), height: max(1, rect.height))
                .offset(isDragging ? dragOffset : .zero)
                .position(x: rect.midX, y: rect.midY)
                .gesture(mode == .zone ? zoneDragGesture(index: i) : nil)
                .contextMenu {
                    Button("Umbenennen / Farbe ändern...") {
                        editingZoneFloorIdx = currentFloorIdx
                        editingZone = plan.floors[currentFloorIdx].zones[i]
                    }
                    Button("Duplizieren") {
                        let z = plan.floors[currentFloorIdx].zones[i]
                        plan.floors[currentFloorIdx].zones.append(ZoneJSON(name: z.name, colorHex: z.colorHex, x: z.x + 0.02, y: z.y + 0.02, width: z.width, height: z.height))
                    }
                    Button("Löschen", role: .destructive) {
                        plan.floors[currentFloorIdx].zones.remove(at: i)
                        selectedZoneIdx = nil
                    }
                }

            if mode == .zone {
                let hs: CGFloat = 10
                ZoneResizeHandle()
                    .frame(width: hs, height: hs)
                    .position(x: rect.minX, y: rect.minY)
                    .gesture(zoneResizeGesture(index: i, corner: .topLeading))
                ZoneResizeHandle()
                    .frame(width: hs, height: hs)
                    .position(x: rect.maxX, y: rect.minY)
                    .gesture(zoneResizeGesture(index: i, corner: .topTrailing))
                ZoneResizeHandle()
                    .frame(width: hs, height: hs)
                    .position(x: rect.minX, y: rect.maxY)
                    .gesture(zoneResizeGesture(index: i, corner: .bottomLeading))
                ZoneResizeHandle()
                    .frame(width: hs, height: hs)
                    .position(x: rect.maxX, y: rect.maxY)
                    .gesture(zoneResizeGesture(index: i, corner: .bottomTrailing))
            }
        }
    }

    // MARK: - Walls Layer

    private var wallsLayer: some View {
        ForEach(plan.walls) { wall in
            if wall.floorIndex == selectedFloor {
                WallLineView(
                    from: CGPoint(x: wall.startX * sc, y: wall.startY * sc),
                    to: CGPoint(x: wall.endX * sc, y: wall.endY * sc),
                    color: .secondary
                )
                .onTapGesture {
                    if mode == .wall {
                        plan.walls.removeAll { $0.id == wall.id }
                    }
                }
                .contextMenu {
                    if mode == .wall {
                        Button("Löschen", role: .destructive) {
                            plan.walls.removeAll { $0.id == wall.id }
                        }
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
                    .position(x: eq.positionX * sc, y: eq.positionY * sc)
                    .gesture(mode == .equipment ? eqDragGesture(index: i) : nil)
                    .contextMenu {
                        Button("Bearbeiten...") {
                            editingEq = plan.equipment[i]
                        }
                        Button("Duplizieren") {
                            let e = plan.equipment[i]
                            plan.equipment.append(EquipmentJSON(name: e.name, type: e.type, iconSystemName: e.iconSystemName, positionX: min(1, e.positionX + 0.03), positionY: min(1, e.positionY + 0.03), floorIndex: e.floorIndex, zone: e.zone, exerciseNames: e.exerciseNames))
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
                    if let start = wallStart, let end = wallPreview, hypot(end.x - start.x, end.y - start.y) > 10 * zoomScale {
                        plan.walls.append(WallJSON(startX: start.x / sc, startY: start.y / sc, endX: end.x / sc, endY: end.y / sc, floorIndex: selectedFloor))
                    }
                    wallStart = nil; wallPreview = nil
                case .zone:
                    if let start = zoneCreationStart, let current = zoneCreationCurrent {
                        let r = normalizedRect(from: start, to: current)
                        if r.width > 0.02 && r.height > 0.02 {
                            plan.floors[currentFloorIdx].zones.append(ZoneJSON(x: r.minX, y: r.minY, width: r.width, height: r.height))
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
                let dx = value.translation.width / sc
                let dy = value.translation.height / sc
                let z = plan.floors[currentFloorIdx].zones[index]
                plan.floors[currentFloorIdx].zones[index].x = snapNorm(max(0, min(1 - z.width, z.x + dx)))
                plan.floors[currentFloorIdx].zones[index].y = snapNorm(max(0, min(1 - z.height, z.y + dy)))
                draggingZoneIdx = nil; dragOffset = .zero
            }
    }

    private enum ResizeCorner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    private func zoneResizeGesture(index: Int, corner: ResizeCorner) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !isResizing {
                    isResizing = true
                    let z = plan.floors[currentFloorIdx].zones[index]
                    resizeStartZone = CGRect(x: z.x, y: z.y, width: z.width, height: z.height)
                }
                let dx = snapNorm(Double(value.translation.width) / sc)
                let dy = snapNorm(Double(value.translation.height) / sc)
                let orig = resizeStartZone
                switch corner {
                case .topLeading:
                    let newX = snapNorm(max(0, min(orig.maxX - snapNorm(0.05), orig.minX + dx)))
                    let newY = snapNorm(max(0, min(orig.maxY - snapNorm(0.05), orig.minY + dy)))
                    plan.floors[currentFloorIdx].zones[index].x = newX
                    plan.floors[currentFloorIdx].zones[index].width = snapNorm(orig.maxX - newX)
                    plan.floors[currentFloorIdx].zones[index].y = newY
                    plan.floors[currentFloorIdx].zones[index].height = snapNorm(orig.maxY - newY)
                case .topTrailing:
                    let newW = snapNorm(max(snapNorm(0.05), min(1 - orig.minX, orig.width + dx)))
                    let newY = snapNorm(max(0, min(orig.maxY - snapNorm(0.05), orig.minY + dy)))
                    plan.floors[currentFloorIdx].zones[index].width = newW
                    plan.floors[currentFloorIdx].zones[index].y = newY
                    plan.floors[currentFloorIdx].zones[index].height = snapNorm(orig.maxY - newY)
                case .bottomLeading:
                    let newX = snapNorm(max(0, min(orig.maxX - snapNorm(0.05), orig.minX + dx)))
                    let newH = snapNorm(max(snapNorm(0.05), min(1 - orig.minY, orig.height + dy)))
                    plan.floors[currentFloorIdx].zones[index].x = newX
                    plan.floors[currentFloorIdx].zones[index].width = snapNorm(orig.maxX - newX)
                    plan.floors[currentFloorIdx].zones[index].height = newH
                case .bottomTrailing:
                    let newW = snapNorm(max(snapNorm(0.05), min(1 - orig.minX, orig.width + dx)))
                    let newH = snapNorm(max(snapNorm(0.05), min(1 - orig.minY, orig.height + dy)))
                    plan.floors[currentFloorIdx].zones[index].width = newW
                    plan.floors[currentFloorIdx].zones[index].height = newH
                }
            }
            .onEnded { _ in
                isResizing = false
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
                plan.equipment[index].positionX = snapNorm(max(0, min(1, eq.positionX + value.translation.width / sc)))
                plan.equipment[index].positionY = snapNorm(max(0, min(1, eq.positionY + value.translation.height / sc)))
                draggingEqIdx = nil; dragOffset = .zero
            }
    }

    // MARK: - Helpers

    private func canvasPoint(_ gesturePoint: CGPoint) -> CGPoint {
        CGPoint(x: gesturePoint.x, y: gesturePoint.y)
    }

    private func snap(_ point: CGPoint) -> CGPoint {
        let step = gridSize * zoomScale
        return CGPoint(x: round(point.x / step) * step, y: round(point.y / step) * step)
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
        return CGRect(x: px.origin.x / sc, y: px.origin.y / sc, width: px.width / sc, height: px.height / sc)
    }
}

// MARK: - Zone Editor Sheet

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
                    for i in plan.floors[floorIdx].zones.indices {
                        if abs(plan.floors[floorIdx].zones[i].x - zone.x) < 0.001 && abs(plan.floors[floorIdx].zones[i].y - zone.y) < 0.001 {
                            plan.floors[floorIdx].zones[i] = zone
                            break
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

                LabeledContent("Icon (SF Symbol)") {
                    HStack {
                        TextField("dumbbell.fill", text: $equipment.iconSystemName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                        Image(systemName: equipment.iconSystemName)
                            .foregroundStyle(.secondary)
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
                    for i in plan.equipment.indices {
                        if abs(plan.equipment[i].positionX - equipment.positionX) < 0.001 && abs(plan.equipment[i].positionY - equipment.positionY) < 0.001 && plan.equipment[i].floorIndex == equipment.floorIndex {
                            plan.equipment[i] = equipment
                            break
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
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(hex: colorHex))
                    .padding(4)
            }
    }
}

struct ZoneResizeHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(.background)
            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.secondary.opacity(0.6), lineWidth: 1))
    }
}

struct EquipmentPinView: View {
    let name: String
    let icon: String
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(hex: "#555555"))
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)

            Text(name)
                .font(.system(size: 6, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 36)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Capsule().fill(.regularMaterial))
        }
        .frame(width: 48, height: 48)
        .contentShape(Rectangle())
    }
}

struct WallLineView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    var body: some View {
        Path { p in p.move(to: from); p.addLine(to: to) }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .contentShape(
                Path { p in p.move(to: from); p.addLine(to: to) }
                    .strokedPath(StrokeStyle(lineWidth: 12, lineCap: .round)),
                eoFill: false
            )
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