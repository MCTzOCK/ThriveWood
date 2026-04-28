//
//  FirstHabitStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct FirstHabitStep: View {
    @Binding var title: String
    @Binding var icon: String
    @Binding var color: HabitColor
    @Binding var points: HabitPoints
    let accent: AccentTheme
    let onNext: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var appear = false

    private let quickSuggestions: [(String, String, HabitColor)] = [
        ("Sport", "figure.run", .orange),
        ("Lesen", "book.fill", .indigo),
        ("Meditation", "brain.head.profile", .purple),
        ("Wasser trinken", "drop.fill", .blue),
        ("Früh aufstehen", "sun.max.fill", .yellow),
        ("Spaziergang", "figure.walk", .green),
        ("Tagebuch", "pencil", .pink),
        ("Kein Zucker", "fork.knife", .red)
    ]

    private let iconOptions = [
        "leaf.fill", "figure.run", "book.fill", "drop.fill",
        "brain.head.profile", "sun.max.fill", "heart.fill",
        "moon.fill", "dumbbell.fill", "fork.knife", "pencil",
        "cup.and.saucer.fill"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer().frame(height: Theme.Spacing.l)

                VStack(spacing: Theme.Spacing.s) {
                    Text("Dein erster Habit")
                        .font(.title2.bold())
                    Text("Womit möchtest du starten?")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .opacity(appear ? 1 : 0)

                // Quick-Suggestions
                FlowLayout(spacing: 8) {
                    ForEach(quickSuggestions, id: \.0) { name, iconName, c in
                        Button {
                            Haptics.selection()
                            title = name; icon = iconName; color = c
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: iconName).font(.caption)
                                Text(name).font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(
                                Capsule().fill(title == name ? c.color : c.color.opacity(0.12))
                            )
                            .foregroundStyle(title == name ? .white : c.color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appear)

                // Custom-Eingabe
                VStack(spacing: Theme.Spacing.m) {
                    TextField("Oder eigener Name…", text: $title)
                        .font(.title3.weight(.semibold))
                        .padding(Theme.Spacing.m)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.m)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )

                    // Icon-Auswahl
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(iconOptions, id: \.self) { name in
                                Button {
                                    Haptics.selection(); icon = name
                                } label: {
                                    Image(systemName: name)
                                        .font(.title3)
                                        .frame(width: 42, height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(icon == name
                                                      ? color.color.opacity(0.2)
                                                      : Color(.tertiarySystemFill))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(icon == name ? color.color : .clear, lineWidth: 2)
                                        )
                                        .foregroundStyle(icon == name ? color.color : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Schwierigkeit
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Schwierigkeit").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Picker("Punkte", selection: $points) {
                            ForEach(HabitPoints.allCases) { p in
                                Text(p.label).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(Theme.Spacing.l)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.l)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.3), value: appear)

                // Vorschau
                if !title.trimmingCharacters(in: .whitespaces).isEmpty {
                    HStack(spacing: Theme.Spacing.m) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .fill(color.gradient)
                                .frame(width: 44, height: 44)
                            Image(systemName: icon)
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading) {
                            Text(title).font(.headline)
                            Text("\(points.rawValue) Punkt\(points.rawValue > 1 ? "e" : "") pro Tag")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                    .padding(Theme.Spacing.m)
                    .cardStyle()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                HStack(spacing: Theme.Spacing.m) {
                    OnboardingBackButton(action: onBack)
                    OnboardingButton(
                        title: title.trimmingCharacters(in: .whitespaces).isEmpty
                            ? "Überspringen" : "Weiter",
                        accent: accent,
                        action: onNext,
                        isSecondary: title.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }

                Spacer().frame(height: Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .onAppear { appear = true }
    }
}

/// Einfaches FlowLayout für die Suggestion-Chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var h: CGFloat = 0
        for row in rows {
            h += row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            h += spacing
        }
        return CGSize(width: proposal.width ?? 0, height: max(0, h - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxW = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var x: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxW && !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(view)
            x += size.width + spacing
        }
        return rows
    }
}
