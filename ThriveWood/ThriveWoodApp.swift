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
    var sharedModelContainer = SharedModelContainer.shared
    @State private var env: AppEnvironment = AppEnvironment(context: SharedModelContainer.shared.mainContext)

    var body: some Scene {
        WindowGroup {
            Group {
                //if let env {
                    RootTabView()
                        .environment(env)
                        .environment(NotificationRouter.shared)
                //} else {
                //    ProgressView()
                //}
            }
            .task {
                //if env == nil {
                    //let e = AppEnvironment(context: sharedModelContainer.mainContext)
                    NotificationRouter.shared.env = env
                    env.notificationService.bootstrap()
                    //env = e
                    await env.storeService.refreshPurchaseState()
                
                // check if userdefault "includeUntrainedMuscles" (bool) is present, otherwise set it to true
                    if UserDefaults.standard.object(forKey: "includeUntrainedMuscles") == nil {
                        UserDefaults.standard.set(true, forKey: "includeUntrainedMuscles")
                    }
                
                //}
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
