//
//  BodyProgressService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import Foundation

@MainActor
@Observable
final class BodyProgressService {
    
    private let repo: BodyProgressRepository
    
    init(repo: BodyProgressRepository) {
        self.repo = repo
    }
    
    func addEntry(_ entry: BodyProgressEntry) {
        do {
            try repo.add(entry)
            ThriveWoodUnio.scheduleExport()
        } catch {

        }
    }
    
    func fetchEntries() -> [BodyProgressEntry] {
        do {
            return try repo.fetchAll()
        } catch {
            return []
        }
    }
    
    func fetchLatestEntry() throws -> BodyProgressEntry? {
        self.fetchEntries().sorted { $0.date > $1.date }.first ?? nil
    }
    
    func deleteEntry(_ entry: BodyProgressEntry) {
        do {
            try repo.delete(entry)
            ThriveWoodUnio.scheduleExport()
        } catch {

        }
    }

    func updateEntry(_ entry: BodyProgressEntry) {
        do {
            try repo.update(entry)
            ThriveWoodUnio.scheduleExport()
        } catch {

        }
    }
    
    func saveImage(_ imageData: Data) throws -> URL {
        let filename = UUID().uuidString + ".jpg"
        let url = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(filename)
        
        try imageData.write(to: url)
        
        return url
    }
    
    func deleteImage(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    
}
