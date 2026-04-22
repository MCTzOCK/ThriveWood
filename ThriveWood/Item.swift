//
//  Item.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
