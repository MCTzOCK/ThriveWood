//
//  HabitGroupDomain.swift
//  ThriveWood
//

import Foundation
import SwiftData

@Model
final class HabitGroup {
    @Attribute(.unique) var id: UUID
    var title: String
    var iconSystemName: String
    var colorRaw: String
    var sortOrder: Int
    var createdAt: Date
    var habitIDs: [UUID]
    var isCollapsed: Bool

    init(
        id: UUID = UUID(),
        title: String,
        iconSystemName: String = "folder.fill",
        color: HabitColor = .green,
        sortOrder: Int = 0,
        habitIDs: [UUID] = [],
        isCollapsed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconSystemName = iconSystemName
        self.colorRaw = color.rawValue
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.habitIDs = habitIDs
        self.isCollapsed = isCollapsed
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .green }
        set { colorRaw = newValue.rawValue }
    }
}
