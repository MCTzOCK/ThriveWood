//
//  GymDomain.swift
//  ThriveWood
//


import Foundation
import SwiftData

@Model
final class Gym {
    @Attribute(.unique) var id: UUID
    var name: String
    var details: String
    var colorRaw: String
    var iconSystemName: String
    var address: String
    var createdAt: Date
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \GymExercise.gym)
    var gymExercises: [GymExercise] = []

    @Relationship(deleteRule: .cascade, inverse: \GymEquipment.gym)
    var equipment: [GymEquipment] = []

    @Relationship(deleteRule: .cascade, inverse: \FloorPlan.gym)
    var floorPlans: [FloorPlan] = []

    @Relationship(deleteRule: .cascade, inverse: \WallSegment.gym)
    var walls: [WallSegment] = []

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        color: HabitColor = .blue,
        iconSystemName: String = "building.2.fill",
        address: String = "",
        createdAt: Date = .now,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.colorRaw = color.rawValue
        self.iconSystemName = iconSystemName
        self.address = address
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }

    var isArchived: Bool { archivedAt != nil }

    var sortedFloorPlans: [FloorPlan] {
        floorPlans.sorted { $0.floorIndex < $1.floorIndex }
    }

    func floorPlan(for floorIndex: Int) -> FloorPlan? {
        floorPlans.first { $0.floorIndex == floorIndex }
    }

    var availableExerciseIDs: Set<UUID> {
        var ids = Set<UUID>()
        for eq in equipment {
            for assignment in eq.exerciseAssignments {
                if let exID = assignment.exercise?.id {
                    ids.insert(exID)
                }
            }
        }
        for ge in gymExercises {
            if let exID = ge.exercise?.id {
                ids.insert(exID)
            }
        }
        return ids
    }
}


@Model
final class GymExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var zoneRaw: String?

    var gym: Gym?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int,
        exercise: Exercise,
        gym: Gym? = nil,
        zone: GymZone? = nil
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.gym = gym
        self.zoneRaw = zone?.rawValue
    }

    var zone: GymZone? {
        get { zoneRaw.flatMap(GymZone.init(rawValue:)) }
        set { zoneRaw = newValue?.rawValue }
    }
}


@Model
final class GymEquipment {
    @Attribute(.unique) var id: UUID
    var name: String
    var equipmentTypeRaw: String
    var positionX: Double
    var positionY: Double
    var floorIndex: Int
    var zoneRaw: String?
    var iconSystemName: String

    var gym: Gym?

    @Relationship(deleteRule: .cascade, inverse: \EquipmentExercise.equipment)
    var exerciseAssignments: [EquipmentExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        equipmentType: EquipmentType = .other,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        floorIndex: Int = 0,
        zone: GymZone? = nil,
        iconSystemName: String = "dumbbell.fill",
        gym: Gym? = nil
    ) {
        self.id = id
        self.name = name
        self.equipmentTypeRaw = equipmentType.rawValue
        self.positionX = positionX
        self.positionY = positionY
        self.floorIndex = floorIndex
        self.zoneRaw = zone?.rawValue
        self.iconSystemName = iconSystemName
        self.gym = gym
    }

    var equipmentType: EquipmentType {
        get { EquipmentType(rawValue: equipmentTypeRaw) ?? .other }
        set { equipmentTypeRaw = newValue.rawValue }
    }

    var zone: GymZone? {
        get { zoneRaw.flatMap(GymZone.init(rawValue:)) }
        set { zoneRaw = newValue?.rawValue }
    }
}


@Model
final class EquipmentExercise {
    @Attribute(.unique) var id: UUID
    var order: Int

    var equipment: GymEquipment?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int,
        exercise: Exercise,
        equipment: GymEquipment? = nil
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.equipment = equipment
    }
}


@Model
final class FloorPlan {
    @Attribute(.unique) var id: UUID
    var floorIndex: Int
    var floorName: String
    var drawingData: Data
    var logicalWidth: Double
    var logicalHeight: Double

    var gym: Gym?

    @Relationship(deleteRule: .cascade, inverse: \FloorZone.floorPlan)
    var zones: [FloorZone] = []

    init(
        id: UUID = UUID(),
        floorIndex: Int = 0,
        floorName: String = "EG",
        drawingData: Data = Data(),
        logicalWidth: Double = 800,
        logicalHeight: Double = 600,
        gym: Gym? = nil
    ) {
        self.id = id
        self.floorIndex = floorIndex
        self.floorName = floorName
        self.drawingData = drawingData
        self.logicalWidth = logicalWidth
        self.logicalHeight = logicalHeight
        self.gym = gym
    }

    var sortedZones: [FloorZone] {
        zones.sorted { $0.name < $1.name }
    }
}


@Model
final class FloorZone {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorRaw: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var floorPlan: FloorPlan?

    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#4CAF50",
        x: Double = 0.1,
        y: Double = 0.1,
        width: Double = 0.3,
        height: Double = 0.3,
        floorPlan: FloorPlan? = nil
    ) {
        self.id = id
        self.name = name
        self.colorRaw = color
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.floorPlan = floorPlan
    }
}


@Model
final class WallSegment {
    @Attribute(.unique) var id: UUID
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double
    var floorIndex: Int

    var gym: Gym?

    init(
        id: UUID = UUID(),
        startX: Double, startY: Double,
        endX: Double, endY: Double,
        floorIndex: Int = 0,
        gym: Gym? = nil
    ) {
        self.id = id
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.floorIndex = floorIndex
        self.gym = gym
    }
}

