//
//  MuscleRankingScreen.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MuscleRankingScreen: View {
    @Environment(AppEnvironment.self) private var env
    
    @State private var rankings: [MuscleRankingData] = []
    @State private var showFront = true
    @State private var selectedMuscle: MuscleGroup?
    @State private var overallRank: MuscleRank = .untrained
    @State private var showLegend = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overallRankHeader
                diagramSection
                
                // Selected Muscle Detail
                if let selected = selectedMuscle,
                   let data = rankings.first(where: { $0.muscleGroup == selected }) {
                    SelectedMuscleCard(data: data) {
                        withAnimation { selectedMuscle = nil }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                muscleListSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Muskel-Ranking")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showLegend = true } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showLegend) {
            RankLegendSheet().presentationDetents([.medium])
        }
        .task { await load() }
        .refreshable { await load() }
    }
    
    // MARK: - Overall Rank
    
    private var overallRankHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(overallRank.primaryColor.opacity(0.12 - Double(i) * 0.03))
                        .frame(width: CGFloat(130 + i * 30))
                        .blur(radius: CGFloat(i * 4))
                }
                
                Circle()
                    .fill(overallRank.gradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: overallRank.glowColor, radius: 12)
                
                Image(systemName: overallRank.icon)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text("Gesamt-Rang").font(.caption).foregroundStyle(.secondary)
            Text(overallRank.label).font(.title.bold()).foregroundStyle(overallRank.primaryColor)
        }
    }
    
    // MARK: - Diagram Section
    
    private var diagramSection: some View {
        VStack(spacing: 16) {
            // Front/Back Toggle
            HStack(spacing: 0) {
                ForEach([true, false], id: \.self) { isFront in
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            showFront = isFront
                            selectedMuscle = nil
                        }
                    } label: {
                        Text(isFront ? "Vorne" : "Hinten")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(showFront == isFront ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                showFront == isFront
                                ? AnyShapeStyle(Color.accentColor)
                                : AnyShapeStyle(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            
            // Muscle Map
            MuscleMapView(
                rankings: rankings,
                selectedMuscle: $selectedMuscle,
                showFront: $showFront
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            
            if selectedMuscle == nil {
                Label("Tippe auf einen Muskel", systemImage: "hand.tap.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }
    
    // MARK: - Muscle List
    
    private var muscleListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alle Muskelgruppen")
                .font(.headline)
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 8) {
                ForEach(rankings.filter { $0.muscleGroup.isPrimaryMuscle }) { data in
                    MuscleRankRow(data: data, isSelected: selectedMuscle == data.muscleGroup) {
                        withAnimation(.spring(response: 0.35)) {
                            selectedMuscle = data.muscleGroup
                            showFront = data.muscleGroup.bodyPosition.isFront
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Load
    
    private func load() async {
        do {
            rankings = try env.muscleRankingService.calculateRankings()
            overallRank = try env.muscleRankingService.overallRank()
        } catch {}
    }
}


