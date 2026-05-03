//
//  ThriveWoodApp.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI
import SwiftData
import OpenFoodFactsSDK

@main
struct ThriveWoodApp: App {
    var sharedModelContainer = SharedModelContainer.shared
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
                    await e.storeService.refreshPurchaseState()
                }
                OFFConfig.shared.apiEnv = .production
                OFFConfig.shared.country = .GERMANY
                OFFConfig.shared.productsLanguage = .GERMAN
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
