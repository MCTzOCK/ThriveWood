//
//  SubscriptionStatusSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 30.04.26.
//


import SwiftUI
import StoreKit

struct SubscriptionStatusSection: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showingPaywall = false
    @State private var showingManage = false

    private var store: StoreService { env.storeService }
    private var isPro: Bool { env.entitlements.isPro }

    var body: some View {
        Section {
            if isPro {
                proStatusCard
            } else {
                freeStatusCard
            }
        } header: {
            Text("Mitgliedschaft")
        }
    }

    // MARK: - Pro-Status

    private var proStatusCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ThriveWood Pro")
                            .font(.headline)
                        Text("AKTIV")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                            .foregroundStyle(.white)
                    }
                    Text(subscriptionDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            Button {
                showingManage = true
            } label: {
                HStack {
                    Image(systemName: "creditcard.fill").foregroundStyle(.blue)
                    Text("Abo verwalten")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .font(.subheadline)
            }
            #if os(iOS)
            .manageSubscriptionsSheet(isPresented: $showingManage)
            #endif

            Button {
                Task { await store.restore() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
                    Text("Käufe wiederherstellen").foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Free-Status

    private var freeStatusCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.tertiaryFill)
                        .frame(width: 48, height: 48)
                    Image(systemName: "leaf.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("ThriveWood Free")
                        .font(.headline)
                    Text(limitsDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Limits-Anzeige
            VStack(spacing: 8) {
                LimitRow(
                    icon: "checklist",
                    label: "Habits",
                    current: currentHabitCount,
                    limit: EntitlementService.freeHabitLimit
                )
                LimitRow(
                    icon: "dumbbell.fill",
                    label: "Workouts",
                    current: currentWorkoutCount,
                    limit: EntitlementService.freeWorkoutLimit
                )
                LimitRow(
                    icon: "pills.fill",
                    label: "Supplements",
                    current: currentSupplementCount,
                    limit: EntitlementService.freeSupplementLimit
                )
            }

            Divider()

            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill").foregroundStyle(.orange)
                    Text("Auf Pro upgraden")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                Task { await store.restore() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
                    Text("Käufe wiederherstellen").foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    // MARK: - Helpers

    private var subscriptionDescription: String {
        let ids = store.purchasedIDs
        if ids.contains(ProProduct.lifetime.rawValue) {
            return "Lifetime – für immer freigeschaltet"
        }
        if ids.contains(ProProduct.yearly.rawValue) {
            return "Jahresabo – verlängert sich automatisch"
        }
        if ids.contains(ProProduct.monthly.rawValue) {
            return "Monatsabo – verlängert sich automatisch"
        }
        return "Aktiv"
    }

    private var limitsDescription: String {
        let remaining = env.entitlements.remainingFreeHabits
        if remaining > 0 {
            return "Noch \(remaining) Habit\(remaining == 1 ? "" : "s") frei"
        }
        return "Habit-Limit erreicht"
    }

    private var currentHabitCount: Int {
        (try? env.habitRepo.fetchAll(includeArchived: false).count) ?? 0
    }

    private var currentWorkoutCount: Int {
        (try? env.workoutRepo.fetchAll(includeArchived: false).count) ?? 0
    }
    
    private var currentSupplementCount: Int {
        (try? env.supplementRepo.fetchAll(includeArchived: false).count) ?? 0
    }
}

// MARK: - Limit-Fortschrittsbalken

private struct LimitRow: View {
    let icon: String
    let label: String
    let current: Int
    let limit: Int
    var showAsFraction: Bool = false

    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(1.0, Double(current) / Double(limit))
    }

    private var isAtLimit: Bool { current >= limit }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label).font(.caption)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(isAtLimit && !showAsFraction ? Color.orange : Color.green)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(width: 80, height: 6)
            Text(showAsFraction
                 ? "\(current)/\(limit)"
                 : "\(current)/\(limit)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(isAtLimit && !showAsFraction ? .orange : .secondary)
        }
    }
}
