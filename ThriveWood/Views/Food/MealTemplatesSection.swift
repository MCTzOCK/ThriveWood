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

struct MealTemplateRow: View {
    let template: MealTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s)
                        .fill(template.color.gradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: template.iconSystemName)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: Theme.Spacing.s) {
                        Text("\(template.items.count) Zutaten")
                        Text("•")
                        Text("\(Int(template.totalNutrition.calories)) kcal")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(template.color.color)
            }
        }
        .buttonStyle(.plain)
    }
}
