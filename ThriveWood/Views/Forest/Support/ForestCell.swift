//
//  ForestCell.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct ForestCell: View {
    let tree: TreeEntity?
    let isWatering: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .aspectRatio(1, contentMode: .fit)

            if let tree {
                TreeShapeView(species: tree.species, stage: tree.stage, animate: isWatering)
                    .padding(4)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .contentShape(Rectangle())
    }
}
