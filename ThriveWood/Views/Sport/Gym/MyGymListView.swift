//
//  MyGymListView.swift
//  ThriveWood
//


import SwiftUI

struct MyGymListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var gyms: [Gym] = []
    @State private var showingNewGym = false
    @State private var selectedGym: Gym?
    @State private var showingPaywall = false
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
                Button {
                    if env.entitlements.canCreateGym {
                        showingNewGym = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
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
}
