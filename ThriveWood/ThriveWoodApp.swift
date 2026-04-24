//
//  ThriveWoodApp.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI
import SwiftData

@main
struct ThriveWoodApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(ThriveWoodSchemaV1.models)
        let modelConfiguration = ModelConfiguration(
            "ThriveWood",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: ThriveWoodMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(AppEnvironment(context: sharedModelContainer.mainContext))
        }
        .modelContainer(sharedModelContainer)
    }
}
