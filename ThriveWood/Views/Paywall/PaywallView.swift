//
//  PaywallView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 29.04.26.
//


import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var selected: ProProduct = .yearly
    @State private var isPurchasing = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    header
                    featureList
                    pricingCards
                    purchaseButton
                    restoreButton
                    legalFooter
                }
                .padding(Theme.Spacing.xl)
            }
            .background(
                LinearGradient(
                    colors: [.green.opacity(0.08), Color(.systemBackground)],
                    startPoint: .top, endPoint: .center
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task { await env.storeService.loadProducts() }
            .alert("Fehler", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "")
            }
            .colorScheme(.dark)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: 8) {
                ForEach([TreeSpecies.cherry, .oak, .sequoia], id: \.self) { s in
                    TreeShapeView(species: s, stage: .mature)
                        .frame(width: 48, height: 60)
                }
            }
            Text("ThriveWood Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.green.gradient)
            Text("Entfalte das volle Potenzial deiner Gewohnheiten")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            ProFeatureRow(icon: "infinity", color: .green,
                          title: "Unbegrenzte Habits",
                          text: "Keine Limits – tracke so viele Gewohnheiten wie du willst")
            ProFeatureRow(icon: "tree.fill", color: .brown,
                          title: "Alle 8 Baumarten",
                          text: "Birke, Ahorn, Kirsche, Mammutbaum und mehr")
            ProFeatureRow(icon: "chart.bar.xaxis", color: .blue,
                          title: "Volle Analyse",
                          text: "30/90/365-Tage-Zeiträume")
            ProFeatureRow(icon: "dumbbell.fill", color: .purple,
                          title: "Unbegrenzte Workouts",
                          text: "Erstelle so viele Trainingspläne wie du brauchst")
            ProFeatureRow(icon: "paintpalette.fill", color: .pink,
                          title: "Themes & App-Icons",
                          text: "6 Akzentfarben, alternative Icons und Dark Mode")
            ProFeatureRow(icon: "square.and.arrow.up", color: .orange,
                          title: "Daten-Export",
                          text: "Volle Kontrolle – exportiere alles als JSON-Backup")
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: Pricing

    private var pricingCards: some View {
        VStack(spacing: Theme.Spacing.m) {
            PricingCard(
                title: "Jährlich", badge: "Beliebteste",
                price: env.storeService.yearlyPrice,
                perMonth: "2,50 €/Monat",
                isSelected: selected == .yearly,
                onTap: { selected = .yearly }
            )
            PricingCard(
                title: "Monatlich", badge: nil,
                price: env.storeService.monthlyPrice,
                perMonth: nil,
                isSelected: selected == .monthly,
                onTap: { selected = .monthly }
            )
            PricingCard(
                title: "Lifetime", badge: "Einmalig",
                price: env.storeService.lifetimePrice,
                perMonth: "Für immer",
                isSelected: selected == .lifetime,
                onTap: { selected = .lifetime }
            )
        }
    }

    // MARK: CTA

    private var purchaseButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text("Jetzt freischalten")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.green.gradient))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private var restoreButton: some View {
        Button {
            Task { await env.storeService.restore(); dismiss() }
        } label: {
            Text("Käufe wiederherstellen")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var legalFooter: some View {
        VStack(spacing: 4) {
            Text("Abonnements verlängern sich automatisch, sofern nicht mindestens 24 Stunden vor Ende der aktuellen Laufzeit gekündigt.")
            HStack(spacing: Theme.Spacing.l) {
                Link("Datenschutz", destination: URL(string: "https://mctzock.github.io/ios-apps-pages/legal/privacy")!)
                Link("AGB", destination: URL(string: "https://mctzock.github.io/ios-apps-pages/legal/terms")!)
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
    }

    // MARK: Logic

    private func purchase() async {
        guard let product = env.storeService.product(for: selected) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let success = try await env.storeService.purchase(product)
            if success { dismiss() }
        } catch { self.error = error }
    }
}

// MARK: - Subviews

private struct ProFeatureRow: View {
    let icon: String; let color: Color; let title: String; let text: String
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct PricingCard: View {
    let title: String; let badge: String?
    let price: String; let perMonth: String?
    let isSelected: Bool; let onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.selection(); onTap() }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Color.green))
                                .foregroundStyle(.white)
                        }
                    }
                    if let perMonth {
                        Text(perMonth).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(price).font(.title3.bold())
            }
            .padding(Theme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .strokeBorder(isSelected ? Color.green : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
