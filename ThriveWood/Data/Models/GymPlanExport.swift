//
//  GymPlanExport.swift
//  ThriveWood
//


import Foundation

struct GymPlanJSON: Codable {
    var name: String
    var iconSystemName: String
    var colorRaw: String
    var floors: [FloorPlanJSON]
    var equipment: [EquipmentJSON]
    var walls: [WallJSON]
}

struct FloorPlanJSON: Codable {
    var floorIndex: Int
    var floorName: String
    var zones: [ZoneJSON]
}

struct ZoneJSON: Codable {
    var name: String
    var colorHex: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct EquipmentJSON: Codable {
    var name: String
    var type: String
    var iconSystemName: String
    var positionX: Double
    var positionY: Double
    var floorIndex: Int
    var zone: String?
    var exerciseNames: [String]
}

struct WallJSON: Codable {
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double
    var floorIndex: Int
}

enum GymPlanExport {
    static func export(gym: Gym) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var floors: [FloorPlanJSON] = []
        for plan in gym.sortedFloorPlans {
            let zones = plan.sortedZones.map { z in
                ZoneJSON(name: z.name, colorHex: z.colorRaw, x: z.x, y: z.y, width: z.width, height: z.height)
            }
            floors.append(FloorPlanJSON(floorIndex: plan.floorIndex, floorName: plan.floorName, zones: zones))
        }
        let equipment: [EquipmentJSON] = gym.equipment.map { eq in
            EquipmentJSON(
                name: eq.name,
                type: eq.equipmentTypeRaw,
                iconSystemName: eq.iconSystemName,
                positionX: eq.positionX,
                positionY: eq.positionY,
                floorIndex: eq.floorIndex,
                zone: eq.zoneRaw,
                exerciseNames: eq.exerciseAssignments.compactMap { $0.exercise?.name }
            )
        }
        let walls: [WallJSON] = gym.walls.map { w in
            WallJSON(startX: w.startX, startY: w.startY, endX: w.endX, endY: w.endY, floorIndex: w.floorIndex)
        }
        let plan = GymPlanJSON(
            name: gym.name,
            iconSystemName: gym.iconSystemName,
            colorRaw: gym.colorRaw,
            floors: floors,
            equipment: equipment,
            walls: walls
        )
        return try encoder.encode(plan)
    }

    static func decode(from data: Data) throws -> GymPlanJSON {
        try JSONDecoder().decode(GymPlanJSON.self, from: data)
    }
}
