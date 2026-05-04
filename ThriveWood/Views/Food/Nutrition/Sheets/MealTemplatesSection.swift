//
//  MealTemplatesSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 03.05.26.
//


import SwiftUI

struct MealTemplatesSection: View {
    @Environment(AppEnvironment.self) private var env
    let mealType: MealType
    let date: Date
    let onLogged: () -> Void

    @State private var templates: [MealTemplate] = []
    @State private var showEditor = false
    @State private var editingTemplate: MealTemplate?

    var body: some View {
        Section("Gespeicherte Mahlzeiten") {
            if templates.isEmpty {
                Text("Keine gespeicherten Mahlzeiten")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(templates, id: \.id) { template in
                    MealTemplateRow(template: template) {
                        logTemplate(template)
                    }
                    .contextMenu {
                        Button {
                            editingTemplate = template
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteTemplate(template)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .task { load() }
        .sheet(item: $editingTemplate) { template in
            MealTemplateEditorView(template: template, initialEntries: nil)
        }
    }

    private func load() {
        templates = (try? env.nutritionService.allTemplates()) ?? []
    }

    private func logTemplate(_ template: MealTemplate) {
        do {
            try env.nutritionService.logMealTemplate(template, mealType: mealType, date: date)
            Haptics.success()
            onLogged()
        } catch {
            Haptics.warning()
        }
    }

    private func deleteTemplate(_ template: MealTemplate) {
        do {
            try env.nutritionService.deleteTemplate(template)
            load()
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }
}


