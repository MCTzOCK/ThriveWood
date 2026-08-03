//
//  RecoveryLegendSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//

import SwiftUI

struct RecoveryLegendSheet: View {
    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                VStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.red.gradient)

                    Text("Erholungs-Analyse")
                        .font(.title.bold())

                    Text("Wissenschaftlich fundierte Pausen-Empfehlungen basierend auf deinem Trainingsvolumen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                VStack(spacing: Theme.Spacing.m) {
                    ForEach(ActivityProfile.allCases) { profile in
                        BentoCard(style: .outlined, padding: .lg) {
                            HStack(spacing: Theme.Spacing.m) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.gradient)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: profile.icon)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.label)
                                        .font(.headline)
                                    Text("Max. \(formatVol(profile.maxWeeklyVolumePerMuscle))/Woche · \(Int(profile.recoveryHours))h Erholung")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if ActivityProfile.current == profile {
                                    Text("Aktiv")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Label("Farben", systemImage: "paintpalette.fill")
                            .font(.headline)

                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.red).frame(width: 14, height: 14)
                                Text("Pause nötig")
                                    .font(.subheadline)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(Color.orange).frame(width: 14, height: 14)
                                Text("Nah am Limit")
                                    .font(.subheadline)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 14, height: 14)
                                Text("Erholt")
                                    .font(.subheadline)
                            }
                        }

                        Label("Faktoren", systemImage: "list.bullet.clipboard.fill")
                            .font(.headline)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Wöchentliches Volumen pro Muskel", systemImage: "chart.bar.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Label("Tage seit letztem Training", systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Label("Aufeinanderfolgende Trainingstage", systemImage: "flame.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Label("Tägliches Set-Volumen", systemImage: "number")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("Die Analyse betrachtet die letzten 7 Tage und empfiehlt Pausen basierend auf wissenschaftlichen Erkenntnissen zur Muskelregeneration. Das Volumen (Gewicht × Reps) wird als Maßstab verwendet, nicht die Anzahl der Sets. Die Schwellenwerte passen sich deinem Aktivitätsprofil an. Empfohlene Pausen sind auf maximal 3 Tage begrenzt.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func formatVol(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.0fk kg", v / 1000)
        }
        return "\(Int(v)) kg"
    }
}