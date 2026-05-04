//
//  SupplementListView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct SupplementListView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedDate: Date
    
    @State private var supplements: [Supplement] = []
    @State private var entries: [SupplementEntry] = []
    @State private var showEditor: Supplement?
    @State private var showCreateSheet = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                WeekStripView(selectedDate: $selectedDate)
                    .padding(.horizontal)
                
                if supplements.isEmpty {
                    emptyState
                } else {
                    ForEach(supplements, id: \.id) { supplement in
                        SupplementCard(
                            supplement: supplement,
                            entries: entries.filter { $0.supplement?.id == supplement.id },
                            date: selectedDate,
                            isEditable: isToday,  // Nur heute bearbeitbar
                            onToggle: { dose in
                                toggleDose(supplement, dose: dose)
                            },
                            onEdit: {
                                showEditor = supplement
                            }
                        )
                    }
                }
            }
            .padding(.vertical)
        }
        .task { await load() }
        .refreshable { await load() }
        .onChange(of: selectedDate) { _, _ in
            Task { await load() }
        }
        .onChange(of: env.supplementService.lastUpdate) { _, _ in
            Task { await load() }
        }
        .sheet(item: $showEditor) { supplement in
            SupplementEditorView(supplement: supplement)
        }
        .sheet(isPresented: $showCreateSheet) {
            SupplementEditorView(supplement: nil)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "pills.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(isToday ? "Keine Supplements" : "Keine Supplements an diesem Tag")
                .font(.headline)
            if isToday {
                Text("Füge deine täglichen Supplements hinzu und werde an die Einnahme erinnert.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    showCreateSheet = true
                } label: {
                    Label("Supplement hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func load() async {
        do {
            // ← Jetzt mit selectedDate statt .now
            supplements = try env.supplementService.supplementsDue(on: selectedDate)
            entries = try env.supplementService.entries(on: selectedDate)
        } catch {
            print("Load error: \(error)")
        }
    }
    
    private func toggleDose(_ supplement: Supplement, dose: Int) {
        // Nur für heute erlauben
        guard isToday else {
            Haptics.warning()
            return
        }
        
        do {
            try env.supplementService.toggleDose(supplement, doseNumber: dose, on: selectedDate)
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }
}

