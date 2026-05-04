//
//  DomainErrors.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case duplicate
    case invalidInput(String)
    case persistenceFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound: "Datensatz wurde nicht gefunden."
        case .duplicate: "Dieser Datensatz existiert bereits."
        case .invalidInput(let msg): "Ungültige Eingabe: \(msg)"
        case .persistenceFailed(let err): "Speichern fehlgeschlagen: \(err.localizedDescription)"
        }
    }
}

enum ServiceError: LocalizedError {
    case insufficientPoints(required: Int, available: Int)
    case speciesLocked(TreeSpecies, requires: Int)
    case gridCellOccupied(x: Int, y: Int)
    case sessionAlreadyActive
    case noActiveSession
    case repository(RepositoryError)

    var errorDescription: String? {
        switch self {
        case .insufficientPoints(let r, let a): "Nicht genug Punkte (benötigt: \(r), verfügbar: \(a))."
        case .speciesLocked(let s, let t): "\(s.rawValue.capitalized) ist erst ab \(t) Punkten verfügbar."
        case .gridCellOccupied(let x, let y): "Position (\(x), \(y)) ist bereits belegt."
        case .sessionAlreadyActive: "Es läuft bereits ein Workout."
        case .noActiveSession: "Kein aktives Workout."
        case .repository(let e): e.errorDescription
        }
    }
}
