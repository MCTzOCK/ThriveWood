//
//  MuscleMapView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//


import SwiftUI

// MARK: - Muscle Map View (Grid-Ansatz)

struct MuscleMapView: View {
    let rankings: [MuscleRankingData]
    @Binding var selectedMuscle: MuscleGroup?
    @Binding var showFront: Bool
    
    private var frontMuscles: [MuscleGroup] {
        [.chest, .shoulders, .biceps, .forearms, .core, .obliques, .quads, .adductors, .hipFlexors, .traps]
    }
    
    private var backMuscles: [MuscleGroup] {
        [.lats, .upperBack, .lowerBack, .triceps, .rearDelts, .glutes, .hamstrings, .calves, .abductors, .traps]
    }
    
    private var activeMuscles: [MuscleGroup] {
        showFront ? frontMuscles : backMuscles
    }
    
    private func data(for muscle: MuscleGroup) -> MuscleRankingData? {
        rankings.first { $0.muscleGroup == muscle }
    }
    
    // Layout: Körperform durch Spaltenbreiten simulieren
    private var rows: [[MuscleGroup]] {
        if showFront {
            return [
                [.traps],                      // Nacken/Trap
                [.shoulders, .chest, .shoulders],  // Oberkörper breit (Schultern = gleicher Eintrag, links/rechts)
                [.biceps, .core, .biceps],         // Mitte
                [.forearms, .obliques, .forearms],  // Unter-Mitte
                [.hipFlexors],                      // Hüfte
                [.quads, .adductors, .quads],       // Beine
            ]
        } else {
            return [
                [.traps],
                [.rearDelts, .upperBack, .rearDelts],
                [.triceps, .lats, .triceps],
                [.lowerBack],
                [.abductors, .glutes, .abductors],
                [.hamstrings, .calves, .hamstrings],
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Kopf (rein dekorativ)
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Color(.systemGray3), lineWidth: 1))
            
            // Muskelreihen
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 4) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, muscle in
                        let d = data(for: muscle)
                        let rank = d?.rank ?? .untrained
                        let isSelected = selectedMuscle == muscle
                        let isCenter = row.count == 3 && colIndex == 1
                        let isSide = row.count == 3 && colIndex != 1
                        
                        MuscleCell(
                            muscle: muscle,
                            rank: rank,
                            isSelected: isSelected,
                            shape: cellShape(rowIndex: rowIndex, isSide: isSide, isCenter: isCenter),
                            height: cellHeight(rowIndex: rowIndex)
                        )
                        .frame(maxWidth: isSide ? 50 : .infinity)
                        .onTapGesture {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMuscle = selectedMuscle == muscle ? nil : muscle
                            }
                        }
                    }
                }
                .padding(.horizontal, paddingForRow(rowIndex))
            }
        }
    }
    
    // MARK: - Layout Helpers
    
    private func cellHeight(rowIndex: Int) -> CGFloat {
        switch rowIndex {
        case 0: return 30          // Traps / Nacken
        case 1: return 65          // Schultern + Brust
        case 2: return 60          // Bizeps + Core
        case 3: return 50          // Unterarme + Obliques
        case 4: return 35          // Hüfte
        case 5: return 90          // Beine
        default: return 50
        }
    }
    
    private func paddingForRow(_ index: Int) -> CGFloat {
        // Erzeugt die Taillierung – oben breit, Mitte schmaler, unten wieder breiter
        switch index {
        case 0: return 60   // Traps schmal
        case 1: return 16   // Schultern breit
        case 2: return 28   // Bizeps etwas schmaler
        case 3: return 38   // Taille schmaler
        case 4: return 50   // Hüfte schmal
        case 5: return 20   // Beine breit
        default: return 24
        }
    }
    
    private func cellShape(rowIndex: Int, isSide: Bool, isCenter: Bool) -> MuscleCell.CellShape {
        if isSide && rowIndex == 1 { return .shoulder }
        if isSide && rowIndex == 2 { return .arm }
        if isSide && rowIndex == 3 { return .forearm }
        if isSide && rowIndex == 5 { return .leg }
        return .standard
    }
}
