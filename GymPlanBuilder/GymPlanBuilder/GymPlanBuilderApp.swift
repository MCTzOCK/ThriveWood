//
//  GymPlanBuilderApp.swift
//  GymPlanBuilder
//


import SwiftUI
import UniformTypeIdentifiers

@main
struct GymPlanBuilderApp: App {
    @State private var plan = GymPlanJSON()

    var body: some Scene {
        WindowGroup {
            ContentView(plan: $plan)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            GymFileCommands(plan: $plan)
        }
    }
}

struct GymFileCommands: Commands {
    @Binding var plan: GymPlanJSON

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Neuer Gym-Plan") { plan = GymPlanJSON() }
                .keyboardShortcut("n", modifiers: [.command])
            Button("JSON öffnen...") { openJSON() }
                .keyboardShortcut("o", modifiers: [.command])
            Button("JSON speichern...") { saveJSON() }
                .keyboardShortcut("s", modifiers: [.command])
        }
    }

    private func openJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let loaded = try? GymPlanJSON.load(from: url) {
            plan = loaded
        }
    }

    private func saveJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(plan.name.replacingOccurrences(of: " ", with: "-")).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? plan.save(to: url)
    }
}
