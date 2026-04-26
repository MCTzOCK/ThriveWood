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
    
    @State private var env: AppEnvironment?

    var body: some Scene {
        WindowGroup {
            Group {
                if let env {
                    RootTabView()
                        .environment(env)
                        .environment(NotificationRouter.shared)
                } else {
                    ProgressView()
                }
            }
            .task {
                if env == nil {
                    let e = AppEnvironment(context: sharedModelContainer.mainContext)
                    NotificationRouter.shared.env = e
                    e.notificationService.bootstrap()
                    env = e
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
