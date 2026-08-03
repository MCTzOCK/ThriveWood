//
//  HintCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct HintCard: View {
    var body: some View {
        BentoCallout(
            kind: .warning,
            title: Text("So wächst dein Wald"),
            message: Text("Tippe auf ein leeres Feld, um einen Baum zu pflanzen. Gieße Bäume, damit sie zum Setzling, Jungbaum und schließlich zum Giganten heranwachsen.")
        )
    }
}
