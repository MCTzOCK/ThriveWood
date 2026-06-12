//
//  AllMealTemplatesView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct AllMealTemplatesView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    
    let mealType: MealType
    let date: Date
    let onLogged: () -> Void
    
    @State private var templates: [MealTemplate] = []
    @State private var editingTemplate: MealTemplate?
    @State private var showCreateTemplate = false
    
    var body: some View {
        List {
            ForEach(templates, id: \.id) { template in
                MealTemplateRow(template: template) {
                    logTemplate(template)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTemplate(template)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                    
                    Button {
                        editingTemplate = template
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .navigationTitle("Alle Mahlzeiten")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingTemplate) { template in
            MealTemplateEditorView(template: template, initialEntries: nil)
        }
        .sheet(isPresented: $showCreateTemplate) {
            MealTemplateEditorView(template: nil, initialEntries: nil)
        }
        .task { load() }
        .onChange(of: env.nutritionService.lastUpdate) { _, _ in load() }
    }
    
    private func load() {
        templates = (try? env.nutritionService.allTemplates()) ?? []
    }
    
    private func logTemplate(_ template: MealTemplate) {
        do {
            try env.nutritionService.logMealTemplate(
                template,
                mealType: mealType,
                date: date
            )
            Haptics.success()
            onLogged()
            dismiss()
        } catch {
            Haptics.warning()
        }
    }
    
    private func deleteTemplate(_ template: MealTemplate) {
        do {
            try env.nutritionService.deleteTemplate(template)
            templates.removeAll { $0.id == template.id }
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }
}
