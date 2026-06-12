//
//  FoodSearchView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//

import SwiftUI

struct FoodSearchView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let selectedDate: Date
    let preselectedMeal: MealType
    var onFoodLogged: ((Food, Double) -> Void)?  // Optional callback für Template-Editor

    @State private var searchText = ""
    @State private var searchResults: [Food] = []
    @State private var recentFoods: [Food] = []
    @State private var favoriteFoods: [Food] = []
    @State private var mealTemplates: [MealTemplate] = []
    @State private var isSearchingOnline = false
    @State private var showScanner = false
    @State private var scannedCode: String?
    @State private var showFoodDetail: Food?
    @State private var showCreateFood = false
    @State private var showCreateTemplate = false
    @State private var selectedMeal: MealType

    // Einfacher Init ohne Callback
    init(selectedDate: Date, preselectedMeal: MealType = .lunch) {
        self.selectedDate = selectedDate
        self.preselectedMeal = preselectedMeal
        self._selectedMeal = State(initialValue: preselectedMeal)
        self.onFoodLogged = nil
    }

    // Init mit Callback (für Template-Editor)
    init(
        selectedDate: Date,
        preselectedMeal: MealType = .lunch,
        onFoodLogged: @escaping (Food, Double) -> Void
    ) {
        self.selectedDate = selectedDate
        self.preselectedMeal = preselectedMeal
        self._selectedMeal = State(initialValue: preselectedMeal)
        self.onFoodLogged = onFoodLogged
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Meal Selector (nur wenn kein Callback, also normaler Flow)
                if onFoodLogged == nil {
                    mealSelector
                }

                searchBar

                List {
                    if searchText.isEmpty {
                        // Templates zuerst
                        if !mealTemplates.isEmpty && onFoodLogged == nil {
                            templatesSection
                        }
                        
                        recentSection
                        favoriteSection
                    } else {
                        resultsSection
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
            .navigationTitle(onFoodLogged != nil ? "Zutat hinzufügen" : "Lebensmittel hinzufügen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateFood = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                #if os(iOS)
                BarcodeScannerView(scannedCode: $scannedCode, isPresented: $showScanner)
                    .ignoresSafeArea()
                #else
                Text("Barcode-Scanner ist nur auf iOS verfügbar.")
                    .padding()
                #endif
            }
            .sheet(item: $showFoodDetail) { food in
                if let callback = onFoodLogged {
                    // Template-Modus: Nur Menge wählen, dann Callback
                    FoodAmountSheet(food: food) { amount in
                        callback(food, amount)
                        dismiss()
                    }
                } else {
                    // Normaler Modus: Voll loggen
                    FoodLogSheet(food: food, date: selectedDate, mealType: selectedMeal) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCreateFood) {
                FoodEditorView(food: nil) { newFood in
                    showFoodDetail = newFood
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                MealTemplateEditorView(template: nil, initialEntries: nil)
            }
            .onChange(of: scannedCode) { _, code in
                guard let code else { return }
                Task { await handleScannedBarcode(code) }
            }
            .task { await loadInitialData() }
        }
    }

    // MARK: - Meal Selector

    private var mealSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                ForEach(MealType.allCases) { meal in
                    Button {
                        Haptics.selection()
                        selectedMeal = meal
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: meal.icon)
                            Text(meal.label)
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selectedMeal == meal ? meal.color : Color.tertiaryFill)
                        )
                        .foregroundStyle(selectedMeal == meal ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Suchen...", text: $searchText)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Theme.Spacing.s)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))

            Button {
                showScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, Theme.Spacing.s)
    }

    // MARK: - Templates Section

    private var templatesSection: some View {
        Section {
            ForEach(mealTemplates.prefix(5), id: \.id) { template in
                MealTemplateRow(template: template) {
                    logTemplate(template)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteTemplate(template)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
            
            if mealTemplates.count > 5 {
                NavigationLink {
                    AllMealTemplatesView(mealType: selectedMeal, date: selectedDate) {
                        dismiss()
                    }
                } label: {
                    Text("Alle anzeigen (\(mealTemplates.count))")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
            }
        } header: {
            HStack {
                Text("Gespeicherte Mahlzeiten")
                Spacer()
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        Section("Zuletzt verwendet") {
            if recentFoods.isEmpty {
                Text("Noch keine Einträge")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentFoods, id: \.id) { food in
                    FoodSearchRow(food: food) {
                        showFoodDetail = food
                    }
                }
            }
        }
    }

    // MARK: - Favorites Section

    private var favoriteSection: some View {
        Section("Favoriten") {
            if favoriteFoods.isEmpty {
                Text("Keine Favoriten")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(favoriteFoods, id: \.id) { food in
                    FoodSearchRow(food: food) {
                        showFoodDetail = food
                    }
                }
            }
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        Section {
            if isSearchingOnline {
                HStack(spacing: Theme.Spacing.s) {
                    ProgressView()
                    Text("Suche online...")
                        .foregroundStyle(.secondary)
                }
            } else if searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("Keine Ergebnisse für \"\(searchText)\"")
                        .foregroundStyle(.secondary)
                    Button("Lebensmittel selbst erstellen") {
                        showCreateFood = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.l)
            } else {
                ForEach(searchResults, id: \.id) { food in
                    FoodSearchRow(food: food) {
                        showFoodDetail = food
                    }
                }
            }
        } header: {
            if !searchResults.isEmpty {
                HStack {
                    Text("Ergebnisse (\(searchResults.count))")
                    Spacer()
                    if !isSearchingOnline {
                        Button {
                            Task { await searchOnline() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                Text("Mehr laden")
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadInitialData() async {
        do {
            recentFoods = try env.nutritionService.recentFoods(limit: 10)
            favoriteFoods = try env.nutritionService.favoriteFoods()
            mealTemplates = try env.nutritionService.allTemplates()
        } catch {
            print("Load error: \(error)")
        }
    }

    private func search() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        do {
            // Erst lokal suchen
            searchResults = try env.nutritionService.searchLocal(query: searchText)
            
            // Bei wenigen Ergebnissen automatisch online suchen
            if searchResults.count < 5 {
                await searchOnline()
            }
        } catch {
            print("Search error: \(error)")
        }
    }

    private func searchOnline() async {
        guard !searchText.isEmpty else { return }
        
        isSearchingOnline = true
        defer { isSearchingOnline = false }

        do {
            let online = try await env.nutritionService.searchOnline(query: searchText)
            
            // Duplikate vermeiden (nach Name+Brand)
            let existingKeys = Set(searchResults.map { "\($0.name)-\($0.brand ?? "")" })
            let filtered = online.filter { food in
                !existingKeys.contains("\(food.name)-\(food.brand ?? "")")
            }
            searchResults.append(contentsOf: filtered)
        } catch {
            print("Online search error: \(error)")
        }
    }

    private func handleScannedBarcode(_ code: String) async {
        defer { scannedCode = nil }
        
        do {
            if let food = try await env.nutritionService.fetchByBarcode(code) {
                await MainActor.run {
                    showFoodDetail = food
                }
            } else {
                // Produkt nicht gefunden - Custom erstellen anbieten
                await MainActor.run {
                    showCreateFood = true
                }
            }
        } catch {
            print("Barcode lookup error: \(error)")
        }
    }

    private func logTemplate(_ template: MealTemplate) {
        do {
            try env.nutritionService.logMealTemplate(
                template,
                mealType: selectedMeal,
                date: selectedDate
            )
            Haptics.success()
            dismiss()
        } catch {
            Haptics.warning()
        }
    }

    private func deleteTemplate(_ template: MealTemplate) {
        do {
            try env.nutritionService.deleteTemplate(template)
            mealTemplates.removeAll { $0.id == template.id }
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }
}
