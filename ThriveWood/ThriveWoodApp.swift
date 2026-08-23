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
    @Environment(\.scenePhase) private var scenePhase
    var sharedModelContainer = SharedModelContainer.shared
    @State private var env: AppEnvironment = AppEnvironment(context: SharedModelContainer.shared.mainContext)

    var body: some Scene {
        WindowGroup {
            BentoThemeHost(family: .paper, mode: .light, contrastMode: .system) {
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
                    if UserDefaults.standard.object(forKey: "activityProfile") == nil {
                        UserDefaults.standard.set(ActivityProfile.moderat.rawValue, forKey: "activityProfile")
                    }
                    
                    //}
                    
                    // Unio: vollständigen Export nach App-Start/Update einplanen
                    ThriveWoodUnio.scheduleExport()
                }
                .onChange(of: scenePhase) { _, phase in
                    // Unio: vollständigen Export beim Wechsel in den Hintergrund schreiben
                    guard phase == .background else { return }
                    Task { await ThriveWoodUnio.scheduler.exportImmediately() }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
