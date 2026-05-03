//
//  OpenFoodFactsProduct.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//

import Foundation
import OpenFoodFactsSDK

actor OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    
    // Deutscher Server für bessere lokale Ergebnisse
    private let baseURL = "https://de.openfoodfacts.org/api/v2"
    private let worldURL = "https://world.openfoodfacts.org/api/v2"

    private init() {}

    func fetchProduct(barcode: String) async throws -> Food? {
        // Erst deutschen Server probieren, dann World
        if let food = try await fetchFromServer(worldURL, barcode: barcode) {
            return food
        }
        return try await fetchFromServer(baseURL, barcode: barcode)
    }

    private func fetchFromServer(_ server: String, barcode: String) async throws -> Food? {
        
        let urlString = "\(server)/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("ThriveWood/1.0 (iOS; contact@thrivewood.app)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }

        let result = try JSONDecoder().decode(OpenFoodFactsProduct.self, from: data)

        guard result.status == 1, let product = result.product else { return nil }

        return Food(
            name: product.productName ?? product.productNameDe ?? "Unbekannt",
            brand: product.brands,
            barcode: barcode,
            caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
            proteinPer100g: product.nutriments?.proteins100g ?? 0,
            carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
            fatPer100g: product.nutriments?.fat100g ?? 0,
            fiberPer100g: product.nutriments?.fiber100g ?? 0,
            sugarPer100g: product.nutriments?.sugars100g ?? 0,
            sodiumPer100g: (product.nutriments?.sodium100g ?? 0) * 1000,
            defaultServingSize: parseServingSize(product.servingSize),
            servingUnit: "g",
            category: .other,
            isUserCreated: false
        )
    }

    func search(query: String, page: Int = 1) async throws -> [Food] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        // Kombinierte Suche: erst DE, dann World
        var results: [Food] = []
        
        // Deutsche Suche
        let deResults = try await searchServer(baseURL, query: encoded, page: page)
        results.append(contentsOf: deResults)
        
        // World Suche falls wenig Ergebnisse
        if results.count < 10 {
            let worldResults = try await searchServer(worldURL, query: encoded, page: page)
            // Duplikate vermeiden
            let existingBarcodes = Set(results.compactMap(\.barcode))
            let filtered = worldResults.filter { food in
                guard let barcode = food.barcode else { return true }
                return !existingBarcodes.contains(barcode)
            }
            results.append(contentsOf: filtered)
        }
        
        return results
    }

    private func searchServer(_ server: String, query: String, page: Int) async throws -> [Food] {
        // Wichtig: search_terms2 für bessere Ergebnisse, countries_tags für DE
        let urlString = "\(server)/cgi/search.pl?" + [
            "search_terms=\(query)",
            "search_simple=1",
            "action=process",
            "page=\(page)",
            "page_size=25",
            "sort_by=unique_scans_n",  // Nach Popularität sortieren
            "json=1",
            "lc=de",                    // Sprache Deutsch
            "cc=de"                     // Land Deutschland
        ].joined(separator: "&")
        
        print(urlString)
        
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("ThriveWood/1.0 (iOS; hello@ben-siebert.de)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return [] }

        struct SearchResponse: Codable {
            let products: [ProductDetails]?
            let count: Int?
            
            struct ProductDetails: Codable {
                let code: String?
                let productName: String?
                let productNameDe: String?
                let brands: String?
                let nutriments: Nutriments?
                let servingSize: String?

                enum CodingKeys: String, CodingKey {
                    case code
                    case productName = "product_name"
                    case productNameDe = "product_name_de"
                    case brands
                    case nutriments
                    case servingSize = "serving_size"
                }
            }
            
            struct Nutriments: Codable {
                let energyKcal100g: Double?
                let proteins100g: Double?
                let carbohydrates100g: Double?
                let fat100g: Double?
                let fiber100g: Double?
                let sugars100g: Double?
                let sodium100g: Double?

                enum CodingKeys: String, CodingKey {
                    case energyKcal100g = "energy-kcal_100g"
                    case proteins100g = "proteins_100g"
                    case carbohydrates100g = "carbohydrates_100g"
                    case fat100g = "fat_100g"
                    case fiber100g = "fiber_100g"
                    case sugars100g = "sugars_100g"
                    case sodium100g = "sodium_100g"
                }
            }
        }

        let result = try JSONDecoder().decode(SearchResponse.self, from: data)

        return (result.products ?? []).compactMap { p in
            // Bevorzuge deutschen Namen, sonst internationalen
            let name = p.productNameDe ?? p.productName
            guard let name, !name.isEmpty else { return nil }
            
            // Nur Produkte mit Nährwerten
            guard let nutriments = p.nutriments,
                  nutriments.energyKcal100g != nil else { return nil }
            
            return Food(
                name: name,
                brand: p.brands,
                barcode: p.code,
                caloriesPer100g: nutriments.energyKcal100g ?? 0,
                proteinPer100g: nutriments.proteins100g ?? 0,
                carbsPer100g: nutriments.carbohydrates100g ?? 0,
                fatPer100g: nutriments.fat100g ?? 0,
                fiberPer100g: nutriments.fiber100g ?? 0,
                sugarPer100g: nutriments.sugars100g ?? 0,
                sodiumPer100g: (nutriments.sodium100g ?? 0) * 1000
            )
        }
    }

    private func parseServingSize(_ str: String?) -> Double {
        guard let str else { return 100 }
        let numbers = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers) ?? 100
    }
}

// Aktualisiertes DTO
struct OpenFoodFactsProduct: Codable {
    let code: String?
    let product: ProductDetails?
    let status: Int

    struct ProductDetails: Codable {
        let productName: String?
        let productNameDe: String?
        let brands: String?
        let nutriments: Nutriments?
        let servingSize: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case productNameDe = "product_name_de"
            case brands
            case nutriments
            case servingSize = "serving_size"
        }
    }

    struct Nutriments: Codable {
        let energyKcal100g: Double?
        let proteins100g: Double?
        let carbohydrates100g: Double?
        let fat100g: Double?
        let fiber100g: Double?
        let sugars100g: Double?
        let sodium100g: Double?

        enum CodingKeys: String, CodingKey {
            case energyKcal100g = "energy-kcal_100g"
            case proteins100g = "proteins_100g"
            case carbohydrates100g = "carbohydrates_100g"
            case fat100g = "fat_100g"
            case fiber100g = "fiber_100g"
            case sugars100g = "sugars_100g"
            case sodium100g = "sodium_100g"
        }
    }
}
