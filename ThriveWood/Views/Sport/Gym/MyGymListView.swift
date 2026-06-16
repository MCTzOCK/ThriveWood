//
//  MyGymListView.swift
//  ThriveWood
//


import SwiftUI
import UniformTypeIdentifiers

struct MyGymListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var gyms: [Gym] = []
    @State private var showingNewGym = false
    @State private var selectedGym: Gym?
    @State private var showingPaywall = false
    @State private var showingImport = false
    @State private var errors = ErrorState()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                if gyms.isEmpty {
                    emptyState
                } else {
                    ForEach(gyms) { gym in
                        GymCard(gym: gym) {
                            selectedGym = gym
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mein Gym")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if env.entitlements.canCreateGym {
                            showingNewGym = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("Neues Gym", systemImage: "plus")
                    }
                    Button {
                        showingImport = true
                    } label: {
                        Label("JSON importieren", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            importJSON(from: result)
        }
        .sheet(isPresented: $showingNewGym) {
            GymEditorView(gym: nil).onDisappear { load() }
        }
        .navigationDestination(item: $selectedGym) { gym in
            GymDetailView(gym: gym)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .errorAlert(errors)
        .onAppear(perform: load)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Noch kein Gym")
                .font(.headline)
            Text("Erstelle dein erstes Gym, um Übungen und Geräte auf einer interaktiven Karte zu verwalten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                if env.entitlements.canCreateGym {
                    showingNewGym = true
                } else {
                    showingPaywall = true
                }
            } label: {
                Label("Gym erstellen", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.xl)
        .cardStyle()
    }

    private func load() {
        do { gyms = try env.gymService.allGyms() }
        catch { errors.show(error) }
    }

    private func importJSON(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let plan = try GymPlanExport.decode(from: data)
                let gym = try env.gymService.createGym(name: plan.name, color: HabitColor(rawValue: plan.colorRaw) ?? .blue, iconSystemName: plan.iconSystemName)
                for floorJSON in plan.floors {
                    let floorPlan = FloorPlan(floorIndex: floorJSON.floorIndex, floorName: floorJSON.floorName, gym: gym)
                    gym.floorPlans.append(floorPlan)
                    for zoneJSON in floorJSON.zones {
                        let zone = FloorZone(name: zoneJSON.name, color: zoneJSON.colorHex, x: zoneJSON.x, y: zoneJSON.y, width: zoneJSON.width, height: zoneJSON.height, floorPlan: floorPlan)
                        floorPlan.zones.append(zone)
                    }
                }
                for wallJSON in plan.walls {
                    _ = try env.gymService.addWall(startX: wallJSON.startX, startY: wallJSON.startY, endX: wallJSON.endX, endY: wallJSON.endY, floorIndex: wallJSON.floorIndex, to: gym)
                }
                let allExercises = (try? env.exerciseRepo.fetchAll()) ?? []
                for eqJSON in plan.equipment {
                    let eq = try env.gymService.addEquipment(name: eqJSON.name, type: EquipmentType(rawValue: eqJSON.type) ?? .other, floorIndex: eqJSON.floorIndex, zone: eqJSON.zone.flatMap { GymZone(rawValue: $0) }, icon: eqJSON.iconSystemName, to: gym)
                    eq.positionX = eqJSON.positionX
                    eq.positionY = eqJSON.positionY
                    for name in eqJSON.exerciseNames {
                        if let exercise = allExercises.first(where: { $0.name == name }) {
                            try env.gymService.assignExercise(exercise, to: eq, in: gym)
                        }
                    }
                }
                try env.gymService.updateGym(gym)
                load()
                Haptics.success()
            } catch {
                errors.show(error)
            }
        case .failure(let error):
            errors.show(error)
        }
    }
}
