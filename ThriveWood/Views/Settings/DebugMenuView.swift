//
//  DebugMenuView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 24.04.26.
//

#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var errors = ErrorState()
    @State private var amount: Int = 10

    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Punkte vergeben") {
                    Stepper("Menge: \(amount)", value: $amount, in: 1...500, step: 5)
                    Button("➕ \(amount) Punkte heute") {
                        run { try env.debugService.grantPoints(amount) }
                    }
                    Button("➕ 100 Punkte verteilt (30 Tage)") {
                        run { try env.debugService.grantPoints(100, distributedOverLast: 30) }
                    }
                }

                Section("Schnellaktionen") {
                    Button("🌱 Beispiel-Daten seeden (60 Tage)") {
                        run { try env.debugService.seedSampleData() }
                    }
                    Button("✅ Alle Habits heute abhaken") {
                        run { try env.debugService.completeAllToday() }
                    }
                    Button("🔔 Test-Notification (5s)") {
                        Task { try? await env.debugService.fireTestNotification() }
                    }
                    Button("🏆 Achievement HUD testen") {
                        env.achievementService.triggerTestNotification()
                    }
                }

                Section("In-App Purchases") {
                    HStack {
                        Text("Pro-Status")
                        Spacer()
                        Text(env.storeService.isProUser ? "✅ Pro" : "❌ Free")
                            .foregroundStyle(env.storeService.isProUser ? .green : .secondary)
                    }
                    HStack {
                        Text("Aktive Produkte")
                        Spacer()
                        Text(env.storeService.purchasedIDs.isEmpty
                             ? "Keine"
                             : env.storeService.purchasedIDs.joined(separator: "\n"))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("🔄 Produkte neu laden") {
                        Task { await env.storeService.loadProducts() }
                    }
                    Button("🔄 Status aktualisieren") {
                        Task { await env.storeService.refreshPurchaseState() }
                    }
                    Button("💳 Paywall öffnen") {
                        showingPaywall = true
                    }
                    Button("🗑️ Alle Käufe zurücksetzen", role: .destructive) {
                        Task {
                            await env.storeService.debugResetAllPurchases()
                            Haptics.success()
                        }
                    }
                }

                
                Section("Zurücksetzen") {
                    Button("Alle Completions löschen", role: .destructive) {
                        run { try env.debugService.resetAllCompletions() }
                    }
                    Button("Wald zurücksetzen", role: .destructive) {
                        run { try env.debugService.resetForest() }
                    }
                    Button("🔥 Alles löschen", role: .destructive) {
                        run { try env.debugService.wipeEverything() }
                    }
                    Button("Sport - Alles Löschen", role: .destructive) {
                        run { try env.debugService.wipeAllSportData() }
                    }
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .errorAlert(errors)
        }
    }

    private func run(_ block: () throws -> Void) {
        do { try block(); Haptics.success() }
        catch { errors.show(error) }
    }
}
#endif
