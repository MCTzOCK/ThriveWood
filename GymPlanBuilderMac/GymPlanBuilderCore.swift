//
//  GymPlanBuilderCore.swift
//  GymPlanBuilder
//


import Foundation

public struct GymPlanJSON: Codable {
    public var name: String
    public var iconSystemName: String
    public var colorRaw: String
    public var floors: [FloorPlanJSON]
    public var equipment: [EquipmentJSON]
    public var walls: [WallJSON]

    public init(name: String = "Mein Gym", iconSystemName: String = "building.2.fill", colorRaw: String = "blue", floors: [FloorPlanJSON] = [FloorPlanJSON()], equipment: [EquipmentJSON] = [], walls: [WallJSON] = []) {
        self.name = name
        self.iconSystemName = iconSystemName
        self.colorRaw = colorRaw
        self.floors = floors
        self.equipment = equipment
        self.walls = walls
    }
}

public struct FloorPlanJSON: Codable {
    public var floorIndex: Int
    public var floorName: String
    public var zones: [ZoneJSON]

    public init(floorIndex: Int = 0, floorName: String = "EG", zones: [ZoneJSON] = []) {
        self.floorIndex = floorIndex
        self.floorName = floorName
        self.zones = zones
    }
}

public struct ZoneJSON: Codable, Identifiable {
    public var id: String { "\(name)-\(x)-\(y)-\(width)-\(height)" }
    public var name: String
    public var colorHex: String
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(name: String = "Sonstiges", colorHex: String = "#757575", x: Double = 0.1, y: Double = 0.1, width: Double = 0.3, height: Double = 0.3) {
        self.name = name
        self.colorHex = colorHex
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct EquipmentJSON: Codable, Identifiable {
    public var id: String { "\(name)-\(positionX)-\(positionY)-\(floorIndex)" }
    public var name: String
    public var type: String
    public var iconSystemName: String
    public var positionX: Double
    public var positionY: Double
    public var floorIndex: Int
    public var zone: String?
    public var exerciseNames: [String]

    public init(name: String = "Gerät", type: String = "other", iconSystemName: String = "dumbbell.fill", positionX: Double = 0.5, positionY: Double = 0.5, floorIndex: Int = 0, zone: String? = nil, exerciseNames: [String] = []) {
        self.name = name
        self.type = type
        self.iconSystemName = iconSystemName
        self.positionX = positionX
        self.positionY = positionY
        self.floorIndex = floorIndex
        self.zone = zone
        self.exerciseNames = exerciseNames
    }
}

public struct WallJSON: Codable, Identifiable {
    public var id: UUID
    public var startX: Double
    public var startY: Double
    public var endX: Double
    public var endY: Double
    public var floorIndex: Int

    public init(id: UUID = UUID(), startX: Double = 0, startY: Double = 0, endX: Double = 0.5, endY: Double = 0, floorIndex: Int = 0) {
        self.id = id
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.floorIndex = floorIndex
    }
}

public enum GymZonePreset: String, CaseIterable {
    case freeWeights, machines, cardio, functional, stretching, platesArea, studio, other

    public var label: String {
        switch self {
        case .freeWeights: "Freihantel"
        case .machines: "Maschinen"
        case .cardio: "Cardio"
        case .functional: "Funktionell"
        case .stretching: "Dehnen"
        case .platesArea: "Scheiben"
        case .studio: "Studio"
        case .other: "Sonstiges"
        }
    }

    public var colorHex: String {
        switch self {
        case .freeWeights: "#E53935"
        case .machines: "#1E88E5"
        case .cardio: "#43A047"
        case .functional: "#FB8C00"
        case .stretching: "#8E24AA"
        case .platesArea: "#6D4C41"
        case .studio: "#00897B"
        case .other: "#757575"
        }
    }
}

public enum EquipmentTypePreset: String, CaseIterable {
    case bench, squatRack, powerRack, cableTower, dumbbellRack, cardioMachine, matArea, pullUpBar, other

    public var label: String {
        switch self {
        case .bench: "Bank"
        case .squatRack: "Squat Rack"
        case .powerRack: "Power Rack"
        case .cableTower: "Kabelzug"
        case .dumbbellRack: "Hantelregal"
        case .cardioMachine: "Cardio-Gerät"
        case .matArea: "Matte"
        case .pullUpBar: "Klimmzugstange"
        case .other: "Sonstiges"
        }
    }

    public var icon: String {
        switch self {
        case .bench: "bed.double.fill"
        case .squatRack: "arrow.up.and.down.text.horizontal"
        case .powerRack: "square.fill"
        case .cableTower: "cable.fill"
        case .dumbbellRack: "dumbbell.fill"
        case .cardioMachine: "heart.fill"
        case .matArea: "rectangle.fill"
        case .pullUpBar: "arrow.up.to.line"
        case .other: "questionmark.square.fill"
        }
    }
}

public extension GymPlanJSON {
    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    static func load(from url: URL) throws -> GymPlanJSON {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GymPlanJSON.self, from: data)
    }
}
