//
//  StoreService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 29.04.26.
//


import StoreKit
import Foundation
import SwiftUI

enum ProProduct: String, CaseIterable {
    case monthly  = "com.bensiebert.thrivewood.pro.monthly"
    case yearly   = "com.bensiebert.thrivewood.pro.yearly"
    case lifetime = "com.bensiebert.thrivewood.pro.lifetime"
}

@MainActor
@Observable
final class StoreService {
    private var updateTask: Task<Void, Never>?

    private(set) var products: [Product] = []
    private(set) var purchasedIDs: Set<String> = []
    private(set) var isProUser: Bool = false


    init() {
        updateTask = Task { await listenForTransactions() }
    }


    // MARK: - Load Products

    func loadProducts() async {
        do {
            let ids = ProProduct.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshPurchaseState()
            await transaction.finish()
            Haptics.success()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshPurchaseState()
    }

    // MARK: - State

    func refreshPurchaseState() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let tx = try? checkVerified(result) {
                ids.insert(tx.productID)
            }
        }
        purchasedIDs = ids
        isProUser = !ids.isEmpty
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.verificationFailed
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let tx = try? checkVerified(result) {
                await refreshPurchaseState()
                await tx.finish()
            }
        }
    }

    // MARK: - Convenience

    func product(for id: ProProduct) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    var monthlyPrice: String {
        product(for: .monthly)?.displayPrice ?? "3,99 €"
    }
    var yearlyPrice: String {
        product(for: .yearly)?.displayPrice ?? "29,99 €"
    }
    var lifetimePrice: String {
        product(for: .lifetime)?.displayPrice ?? "59,99 €"
    }
}

enum StoreError: LocalizedError {
    case verificationFailed
    var errorDescription: String? { "Kauf konnte nicht verifiziert werden." }
}


#if DEBUG
extension StoreService {
    /// Finalisiert alle aktiven Transactions → StoreKit behandelt sie als „abgeschlossen".
    /// Bei nächstem `refreshPurchaseState()` ist der User wieder Free.
    func debugResetAllPurchases() async {
        for await result in Transaction.currentEntitlements {
            if let tx = try? checkVerified(result) {
                await tx.finish()
            }
        }
        // Danach alle unfinished auch aufräumen
        for await result in Transaction.unfinished {
            if let tx = try? checkVerified(result) {
                await tx.finish()
            }
        }
        purchasedIDs.removeAll()
        isProUser = false
    }
}
#endif
