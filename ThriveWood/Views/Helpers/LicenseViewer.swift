//
//  LicenseViewer.swift
//  ThriveWood
//
//  Created by Ben Siebert on 20.05.26.
//


import SwiftUI

public struct OpenSourceLibrary: Identifiable {
    public init(name: String, copyright: String, licenseText: String) {
        self.name = name
        self.copyright = copyright
        self.licenseText = licenseText
    }
    public let id = UUID()
    public let name: String
    public let copyright: String
    public let licenseText: String
}


public struct LicenseViewer: View {
    public let libraries: [OpenSourceLibrary]
    
    public init(libraries: [OpenSourceLibrary]) {
        self.libraries = libraries
    }
    
    public var body: some View {
        List(libraries) { library in
            NavigationLink(destination: LicenseDetailView(library: library)) {
                VStack(alignment: .leading) {
                    Text(library.name)
                        .font(.headline)
                    Text(library.copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(Text("Lizenzen"))
    }
}

struct LicenseDetailView: View {
    let library: OpenSourceLibrary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Titel und Copyright noch einmal oben
                VStack(alignment: .leading) {
                    Text(library.name)
                        .font(.largeTitle)
                        .bold()
                    Text(library.copyright)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Der eigentliche Lizenztext
                Text(library.licenseText)
                    .font(.caption) // Kleiner Text ist üblich für Lizenzen
                    .monospaced()   // Monospace sieht "technischer/rechtlicher" aus
            }
            .padding()
        }
        .navigationTitle(library.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
