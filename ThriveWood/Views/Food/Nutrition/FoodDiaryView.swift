//
//  FoodDiaryView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct FoodDiaryView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedDate: Date

    @State private var entries: [MealType: [FoodEntry]] = [:]
    @State private var totals: NutritionValues = .zero
    @State private var goals: NutritionGoals = .default
    @State private var showGoalEditor = false
    @State private var showAddFood = false
    @State private var selectedMealForAdd: MealType = .lunch

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                WeekStripView(selectedDate: $selectedDate)
                    .padding(.horizontal)

                macroSummaryCard

                ForEach(MealType.allCases) { meal in
                    mealSection(meal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 100)
        }
        .task { await load() }
        .refreshable { await load() }
        .onChange(of: selectedDate) { _, _ in Task { await load() } }
        .onChange(of: env.nutritionService.lastUpdate) { _, _ in
            Task { await load() }  // ← Auto-Refresh!
        }
        .sheet(isPresented: $showGoalEditor) {
            NutritionGoalEditor(goals: $goals) { newGoals in
                try? env.nutritionService.updateGoals(newGoals)
            }
        }
        .sheet(isPresented: $showAddFood) {
            FoodSearchView(selectedDate: selectedDate, preselectedMeal: selectedMealForAdd)
        }
    }

    // MARK: - Meal Section (mit + Button)

    private func mealSection(_ meal: MealType) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: meal.icon)
                    .foregroundStyle(meal.color)
                Text(meal.label)
                    .font(.headline)
                Spacer()

                if let mealEntries = entries[meal], !mealEntries.isEmpty {
                    let mealCals = mealEntries.reduce(0.0) { $0 + $1.nutrition.calories }
                    Text("\(Int(mealCals)) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // + Button pro Mahlzeit
                Button {
                    selectedMealForAdd = meal
                    showAddFood = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(meal.color)
                }
            }
            .padding(.horizontal)

            if let mealEntries = entries[meal], !mealEntries.isEmpty {
                ForEach(mealEntries, id: \.id) { entry in
                    FoodEntryRow(entry: entry) {
                        deleteEntry(entry)
                    }
                }
            } else {
                Button {
                    selectedMealForAdd = meal
                    showAddFood = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Hinzufügen")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }

    
    private var macroSummaryCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack {
                Text("Tagesübersicht")
                    .font(.headline)
                Spacer()
                Button {
                    showGoalEditor = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                }
            }

            // Kalorien-Ring
            HStack(spacing: Theme.Spacing.l) {
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: min(1, totals.calories / max(1, goals.calories)))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Int(totals.calories))")
                            .font(.title2.bold().monospacedDigit())
                        Text("/ \(Int(goals.calories))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    MacroRow(
                        label: "Protein",
                        value: totals.protein,
                        goal: goals.protein,
                        color: .blue,
                        unit: "g"
                    )
                    MacroRow(
                        label: "Kohlenhydrate",
                        value: totals.carbs,
                        goal: goals.carbs,
                        color: .green,
                        unit: "g"
                    )
                    MacroRow(
                        label: "Fett",
                        value: totals.fat,
                        goal: goals.fat,
                        color: .yellow,
                        unit: "g"
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .padding(.horizontal)
    }

    private func load() async {
        do {
            entries = try env.nutritionService.entriesGroupedByMeal(on: selectedDate)
            totals = try env.nutritionService.totalNutrition(on: selectedDate)
            goals = try env.nutritionService.goals()
        } catch {
            print("Load error: \(error)")
        }
    }
    
    private func deleteEntry(_ entry: FoodEntry) {
        do {
            try env.nutritionService.deleteEntry(entry)
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }
}
