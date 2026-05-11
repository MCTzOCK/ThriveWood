//
//  TrainingsPlanDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//


import SwiftUI

struct TrainingsPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    let plan: TrainingsPlan
    
    @State private var showEditSheet = false
    @State private var selectedDay: TrainingsPlanDay?
    
    var body: some View {
        List {
            // Header Info
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color(hex: plan.color) ?? .blue)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.title2.bold())
                            
                            if !plan.details.isEmpty {
                                Text(plan.details)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack(alignment: .center, spacing: 20) {
                        StatBadge(
                            icon: "calendar",
                            value: "\(plan.trainingDaysPerWeek)",
                            label: "Tage/Woche",
                            color: Color(hex: plan.color) ?? .blue
                        )
                        
                        StatBadge(
                            icon: "dumbbell.fill",
                            value: "\(plan.totalExercises)",
                            label: "Übungen",
                            color: .orange
                        )
                        
                        StatBadge(
                            icon: plan.isActive ? "checkmark.seal.fill" : "circle",
                            value: plan.isActive ? "Aktiv" : "Inaktiv",
                            label: "",
                            color: plan.isActive ? .green : .gray
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }
            
            // Wochenplan
            Section {
                ForEach(plan.sortedDays) { day in
                    WeekdayRow(day: day) {
                        selectedDay = day
                    }
                }
            } header: {
                Text("Wochenplan")
            }
        }
        .navigationTitle("Trainingsplan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Bearbeiten")
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Fertig") { dismiss() }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditTrainingsPlanSheet(plan: plan)
        }
        .sheet(item: $selectedDay) { day in
            NavigationStack {
                EditDaySheet(day: day, plan: plan)
            }
        }
    }
}

