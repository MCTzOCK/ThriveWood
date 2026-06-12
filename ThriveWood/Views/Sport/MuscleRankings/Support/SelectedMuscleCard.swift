//
//  SelectedMuscleCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct SelectedMuscleCard: View {
    let data: MuscleRankingData
    let onClose: () -> Void

    @State private var progressAnimated = false
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(data.rank.gradient)
                        .frame(width: 56, height: 56)
                        //.shadow(color: data.rank.glowColor, radius: 8)
                    
                    Image(systemName: data.rank.icon)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.muscleGroup.label)
                        .font(.title3.bold())
                    
                    Text(data.rank.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(data.rank.primaryColor)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .tint(data.rank.primaryColor)
            }
            
            // Progress
            if data.rank != .legend {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Fortschritt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(data.progressToNext * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.systemGray5)
                            
                            Capsule()
                                .fill(data.rank.gradient)
                                .frame(width: geo.size.width * (progressAnimated ? data.progressToNext : 0))
                        }
                    }
                    .frame(height: 8)
                    
                    if let volumeToNext = data.rank.volumeToNext(currentVolume: Int(data.totalVolume)),
                       let next = MuscleRank(rawValue: data.rank.rawValue + 1) {
                        Text("Noch \(volumeToNext) kg bis \(next.label)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            // Stats
            HStack(spacing: 24) {
                StatItem(icon: "number", value: "\(data.totalSets)", label: "Sets")
                StatItem(icon: "scalemass.fill", value: formatVolume(data.totalVolume), label: "Volumen")
                StatItem(icon: "calendar", value: formatDate(data.lastWorked), label: "Zuletzt")
            }
            /*
            // Library Button
            Button {
                withAnimation {
                    onLibraryOpen()
                }
            } label: {
                HStack(spacing: Theme.Spacing.l) {
                    Image(systemName: "book.closed")
                    Text("Übungen ansehen")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.systemBackground)
                .cornerRadius(8)
            }
            .tint(data.rank.primaryColor)*/
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.secondarySystemBackground : Color.systemBackground)
                .shadow(color: data.rank.glowColor.opacity(0.2), radius: 20)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                progressAnimated = true
            }
        }
    }
    
    private func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }
    
    private func formatDate(_ d: Date?) -> String {
        guard let d else { return "—" }
        let days = Calendar.current.dateComponents([.day], from: d, to: .now).day ?? 0
        if days == 0 { return "Heute" }
        if days == 1 { return "Gestern" }
        return "\(days)d"
    }
}
