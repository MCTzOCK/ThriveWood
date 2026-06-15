//
//  GymService.swift
//  ThriveWood
//


import Foundation

@MainActor
@Observable
final class GymService {
    private let gymRepo: any GymRepository
    private let exerciseRepo: any ExerciseRepository

    init(gymRepo: any GymRepository, exerciseRepo: any ExerciseRepository) {
        self.gymRepo = gymRepo
        self.exerciseRepo = exerciseRepo
    }

    // MARK: - Gym CRUD

    func allGyms() throws -> [Gym] {
        try gymRepo.fetchAll(includeArchived: false)
    }

    func gym(by id: UUID) throws -> Gym? {
        try gymRepo.fetch(id: id)
    }

    func createGym(name: String, details: String = "", color: HabitColor = .blue, iconSystemName: String = "building.2.fill", address: String = "") throws -> Gym {
        let gym = Gym(name: name, details: details, color: color, iconSystemName: iconSystemName, address: address)
        try gymRepo.create(gym)
        Haptics.success()
        return gym
    }

    func updateGym(_ gym: Gym) throws {
        try gymRepo.update(gym)
    }

    func archiveGym(_ gym: Gym) throws {
        try gymRepo.archive(gym)
    }

    func deleteGym(_ gym: Gym) throws {
        try gymRepo.delete(gym)
        Haptics.impact()
    }

    // MARK: - GymExercise

    func addExercise(_ exercise: Exercise, to gym: Gym, zone: GymZone? = nil) throws {
        let order = gym.gymExercises.count
        let ge = GymExercise(order: order, exercise: exercise, gym: gym, zone: zone)
        gym.gymExercises.append(ge)
        try gymRepo.update(gym)
    }

    func removeExercise(_ gymExercise: GymExercise, from gym: Gym) throws {
        gym.gymExercises.removeAll { $0.id == gymExercise.id }
        for (i, ge) in gym.gymExercises.sorted(by: { $0.order < $1.order }).enumerated() { ge.order = i }
        try gymRepo.update(gym)
    }

    // MARK: - Equipment CRUD

    func addEquipment(name: String, type: EquipmentType, floorIndex: Int = 0, zone: GymZone? = nil, icon: String = "dumbbell.fill", to gym: Gym) throws -> GymEquipment {
        let existingOnFloor = gym.equipment.filter { $0.floorIndex == floorIndex }.count
        let stagger = Double(existingOnFloor % 5) * 0.06
        let row = Double(existingOnFloor / 5) * 0.08
        let px = min(0.9, 0.3 + stagger)
        let py = min(0.9, 0.3 + row)
        let eq = GymEquipment(name: name, equipmentType: type, positionX: px, positionY: py, floorIndex: floorIndex, zone: zone, iconSystemName: icon, gym: gym)
        gym.equipment.append(eq)
        try gymRepo.update(gym)
        return eq
    }

    func updateEquipment(_ eq: GymEquipment, in gym: Gym) throws {
        try gymRepo.update(gym)
    }

    func removeEquipment(_ eq: GymEquipment, from gym: Gym) throws {
        gym.equipment.removeAll { $0.id == eq.id }
        try gymRepo.update(gym)
    }

    func saveEquipmentPosition(_ eq: GymEquipment, x: Double, y: Double, in gym: Gym) throws {
        eq.positionX = x
        eq.positionY = y
        try gymRepo.update(gym)
    }

    // MARK: - EquipmentExercise

    func assignExercise(_ exercise: Exercise, to equipment: GymEquipment, in gym: Gym) throws {
        let order = equipment.exerciseAssignments.count
        let ee = EquipmentExercise(order: order, exercise: exercise, equipment: equipment)
        equipment.exerciseAssignments.append(ee)
        try gymRepo.update(gym)
    }

    func removeAssignment(_ assignment: EquipmentExercise, from equipment: GymEquipment, in gym: Gym) throws {
        equipment.exerciseAssignments.removeAll { $0.id == assignment.id }
        for (i, ee) in equipment.exerciseAssignments.sorted(by: { $0.order < $1.order }).enumerated() { ee.order = i }
        try gymRepo.update(gym)
    }

    // MARK: - FloorPlan

    func addFloorPlan(to gym: Gym, name: String = "EG") throws -> FloorPlan {
        let index = gym.floorPlans.count
        let plan = FloorPlan(floorIndex: index, floorName: name, gym: gym)
        gym.floorPlans.append(plan)
        try gymRepo.update(gym)
        return plan
    }

    func updateFloorPlanDrawing(_ plan: FloorPlan, data: Data, in gym: Gym) throws {
        plan.drawingData = data
        try gymRepo.update(gym)
    }

    func removeFloorPlan(_ plan: FloorPlan, from gym: Gym) throws {
        gym.floorPlans.removeAll { $0.id == plan.id }
        for (i, fp) in gym.sortedFloorPlans.enumerated() { fp.floorIndex = i }
        try gymRepo.update(gym)
    }

    func renameFloorPlan(_ plan: FloorPlan, name: String, in gym: Gym) throws {
        plan.floorName = name
        try gymRepo.update(gym)
    }

    // MARK: - FloorZone

    func addZone(name: String, color: String, x: Double, y: Double, width: Double, height: Double, to plan: FloorPlan, in gym: Gym) throws -> FloorZone {
        let zone = FloorZone(name: name, color: color, x: x, y: y, width: width, height: height, floorPlan: plan)
        plan.zones.append(zone)
        try gymRepo.update(gym)
        return zone
    }

    func updateZone(_ zone: FloorZone, in gym: Gym) throws {
        try gymRepo.update(gym)
    }

    func removeZone(_ zone: FloorZone, from plan: FloorPlan, in gym: Gym) throws {
        plan.zones.removeAll { $0.id == zone.id }
        try gymRepo.update(gym)
    }

    func updateZonePosition(_ zone: FloorZone, x: Double, y: Double, width: Double, height: Double, in gym: Gym) throws {
        zone.x = x
        zone.y = y
        zone.width = width
        zone.height = height
        try gymRepo.update(gym)
    }

    // MARK: - Walls

    func addWall(startX: Double, startY: Double, endX: Double, endY: Double, floorIndex: Int = 0, to gym: Gym) throws -> WallSegment {
        let wall = WallSegment(startX: startX, startY: startY, endX: endX, endY: endY, floorIndex: floorIndex, gym: gym)
        gym.walls.append(wall)
        try gymRepo.update(gym)
        return wall
    }

    func removeWall(_ wall: WallSegment, from gym: Gym) throws {
        gym.walls.removeAll { $0.id == wall.id }
        try gymRepo.update(gym)
    }

    func walls(onFloor floorIndex: Int, in gym: Gym) -> [WallSegment] {
        gym.walls.filter { $0.floorIndex == floorIndex }
    }

    // MARK: - Queries

    func equipment(onFloor floorIndex: Int, in gym: Gym) -> [GymEquipment] {
        gym.equipment.filter { $0.floorIndex == floorIndex }
    }

    func allExercises(in gym: Gym) -> [Exercise] {
        let ids = gym.availableExerciseIDs
        return (try? exerciseRepo.fetchAll().filter { ids.contains($0.id) }) ?? []
    }

    func equipmentForExercise(_ exercise: Exercise, in gym: Gym) -> [GymEquipment] {
        gym.equipment.filter { eq in
            eq.exerciseAssignments.contains { $0.exercise?.id == exercise.id }
        }
    }
}
