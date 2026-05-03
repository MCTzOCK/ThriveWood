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


struct SupplementCard: View {
    let supplement: Supplement
    let entries: [SupplementEntry]
    let date: Date
    let isEditable: Bool  // ← NEU
    let onToggle: (Int) -> Void
    let onEdit: () -> Void
    
    private func isTaken(dose: Int) -> Bool {
        entries.contains { $0.doseNumber == dose && !$0.skipped }
    }
    
    private func isSkipped(dose: Int) -> Bool {
        entries.contains { $0.doseNumber == dose && $0.skipped }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(supplement.color.gradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: supplement.iconSystemName)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(supplement.name)
                        .font(.headline)
                    Text(supplement.dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isEditable {
                    Button(action: onEdit) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            
            HStack(spacing: Theme.Spacing.s) {
                ForEach(1...supplement.timesPerDay, id: \.self) { dose in
                    Button {
                        if isEditable {
                            onToggle(dose)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                if isSkipped(dose: dose) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                } else {
                                    Image(systemName: isTaken(dose: dose) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(isTaken(dose: dose) ? supplement.color.color : .secondary)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            
                            if supplement.timesPerDay > 1, dose <= supplement.reminderTimes.count {
                                Text(supplement.reminderTimes[dose - 1].formatted(.dateTime.hour().minute()))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                                .fill(backgroundColor(for: dose))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEditable)
                    .opacity(isEditable ? 1 : 0.7)
                }
            }
            if !isEditable {
                let taken = (1...supplement.timesPerDay).filter { isTaken(dose: $0) }.count
                let total = supplement.timesPerDay
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: taken == total ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(taken == total ? .green : .secondary)
                    Text("\(taken)/\(total) eingenommen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .padding(.horizontal)
    }
    
    private func backgroundColor(for dose: Int) -> Color {
        if isSkipped(dose: dose) {
            return Color.orange.opacity(0.1)
        } else if isTaken(dose: dose) {
            return supplement.color.color.opacity(0.1)
        } else {
            return Color(.tertiarySystemFill)
        }
    }
    
}
