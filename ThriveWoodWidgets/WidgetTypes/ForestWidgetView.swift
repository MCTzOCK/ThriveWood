//
//  ForestWidgetView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import SwiftUI
import WidgetKit
import AppIntents

struct ForestWidgetView: View {
    let entry: ForestEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        case .systemLarge:  largeView
        default:            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tree.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green.gradient)
            Text("\(Int(entry.coverage * 100))%")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            Text("bewachsen")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tree.fill").foregroundStyle(.green)
                    Text("Mein Wald").font(.headline)
                }
                Text("\(Int(entry.coverage * 100))%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("bewachsen").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                StatRow(icon: "tree.fill", value: "\(entry.treeCount)", label: "Bäume")
                StatRow(icon: "leaf.fill", value: "\(entry.species)", label: "Arten")
                StatRow(icon: "star.fill", value: "\(entry.availablePoints)", label: "Verfügbar")
            }
        }
        .padding()
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tree.fill").foregroundStyle(.green)
                Text("Mein Wald").font(.headline)
                Spacer()
                Text("\(Int(entry.coverage * 100))% bewachsen")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }

            // Mini-Grid
            miniForestGrid

            HStack(spacing: 16) {
                MiniKPI(icon: "tree.fill", value: "\(entry.treeCount)", label: "Bäume", tint: .green)
                MiniKPI(icon: "leaf.fill", value: "\(entry.species)", label: "Arten", tint: .mint)
                MiniKPI(icon: "star.fill", value: "\(entry.availablePoints)", label: "Punkte", tint: .orange)
            }
        }
        .padding()
    }

    private var miniForestGrid: some View {
        let cols = 8, rows = 6
        let occupied = Set(entry.trees.map { "\($0.gridX)-\($0.gridY)" })
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: cols), spacing: 2) {
            ForEach(0..<(rows * cols), id: \.self) { i in
                let x = i % cols, y = i / cols
                let key = "\(x)-\(y)"
                RoundedRectangle(cornerRadius: 2)
                    .fill(occupied.contains(key) ? Color.green : Color.secondary.opacity(0.12))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private struct StatRow: View {
        let icon: String; let value: String; let label: String
        var body: some View {
            HStack(spacing: 4) {
                Text(value).font(.subheadline.weight(.bold).monospacedDigit())
                Image(systemName: icon).font(.caption2).foregroundStyle(.green)
            }
        }
    }

    private struct MiniKPI: View {
        let icon: String; let value: String; let label: String; let tint: Color
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.caption).foregroundStyle(tint)
                Text(value).font(.headline.monospacedDigit())
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
