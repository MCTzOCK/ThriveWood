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
    @State private var overallProgress: Double = 0
    @State private var overallVolume: Double = 0
    @State private var showLegend = false
    @State private var progressAnimated = false
    @State private var glowPhase: CGFloat = 0
    @State private var shimmerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var flipAngle: Double = 0
    @State private var isFlipped: Bool = false
    
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
        VStack(spacing: 20) {
            ZStack {
                // Outermost glow ring
                Circle()
                    .stroke(overallRank.primaryColor.opacity(0.15), lineWidth: 20)
                    .frame(width: 140, height: 140)
                    .blur(radius: 8)
                    .scaleEffect(1 + glowPhase * 0.1)
                
                // Progress ring background
                Circle()
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                
                // Progress ring (circular)
                Circle()
                    .trim(from: 0, to: progressAnimated ? overallProgress : 0)
                    .stroke(
                        overallRank.gradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: overallRank.primaryColor, radius: 4)
                
                // Rotating shimmer arc
                Circle()
                    .trim(from: 0, to: 0.15)
                    .stroke(
                        .white.opacity(0.6),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(shimmerRotation))
                    .mask(
                        Circle()
                            .trim(from: 0, to: progressAnimated ? overallProgress : 0)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                    )
                
                // Inner glow behind main circle
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(overallRank.primaryColor.opacity(0.3 - Double(i) * 0.08))
                        .frame(width: CGFloat(100 - i * 10), height: CGFloat(100 - i * 10))
                        .blur(radius: CGFloat(15 - i * 3))
                        .scaleEffect(pulseScale)
                }
                
                // Flippable coin
                ZStack {
                    // Front side (Rank Icon)
                    Circle()
                        .fill(overallRank.gradient)
                        .frame(width: 90, height: 90)
                        .shadow(color: overallRank.primaryColor, radius: 20)
                        .shadow(color: overallRank.primaryColor.opacity(0.5), radius: 40)
                        .scaleEffect(pulseScale)
                        .overlay(
                            Image(systemName: overallRank.icon)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                        )
                        .opacity(flipAngle < 90 ? 1 : 0)
                    
                    // Back side (Progress Details)
                    Circle()
                        .fill(overallRank.gradient)
                        .frame(width: 90, height: 90)
                        .shadow(color: overallRank.primaryColor, radius: 20)
                        .shadow(color: overallRank.primaryColor.opacity(0.5), radius: 40)
                        .overlay(
                            VStack(spacing: 2) {
                                if let next = MuscleRank(rawValue: overallRank.rawValue + 1) {
                                    Text(formatVolume(overallVolume))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("/")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(formatVolume(Double(next.minVolume)))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text("kg")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.7))
                                } else {
                                    Text("∞")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        )
                        .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                        .opacity(flipAngle >= 90 ? 1 : 0)
                }
                .rotation3DEffect(.degrees(flipAngle), axis: (0, 1, 0))
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        flipAngle = isFlipped ? 0 : 180
                        isFlipped.toggle()
                    }
                    Haptics.impact(.medium)
                }
            }
            .frame(height: 160)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    shimmerRotation = 360
                }
            }
            
            VStack(spacing: 6) {
                Text("Gesamt-Rang")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text(overallRank.label)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(overallRank.gradient)
            }
            
            if overallRank != .legend, let next = MuscleRank(rawValue: overallRank.rawValue + 1) {
                HStack(spacing: 8) {
                    Text("\(Int(overallProgress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(overallRank.primaryColor)
                    
                    Text("→")
                        .foregroundStyle(.secondary)
                    
                    Text(next.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(next.primaryColor)
                }
            }
        }
        .padding(.top, 20)
    }
    
    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return "\(Int(v))"
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
            AnatomicMuscleMapView(
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
                ForEach(rankings.filter { $0.muscleGroup.showInList }.sorted(  by: { $0.totalVolume > $1.totalVolume })) { data in
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
        progressAnimated = false
        do {
            rankings = try env.muscleRankingService.calculateRankings()
            overallRank = try env.muscleRankingService.overallRank()
            let totalVolume = rankings.map { $0.totalVolume }.reduce(0, +)
            let avgVolume = rankings.isEmpty ? 0 : totalVolume / Double(rankings.count)
            overallVolume = avgVolume
            overallProgress = overallRank.progressToNext(currentVolume: Int(avgVolume))
        } catch {}
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            progressAnimated = true
        }
    }
}


