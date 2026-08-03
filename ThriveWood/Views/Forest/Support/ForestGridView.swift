//
//  ForestGridView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct ForestGridView: View {
    @Bindable var vm: ForestViewModel

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<vm.gridHeight, id: \.self) { y in
                HStack(spacing: 6) {
                    ForEach(0..<vm.gridWidth, id: \.self) { x in
                        ForestCell(
                            tree: vm.tree(at: x, y: y),
                            isWatering: vm.tree(at: x, y: y).map { vm.wateringTreeID == $0.id } ?? false
                        )
                        .onTapGesture { vm.tapCell(x: x, y: y) }
                    }
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            LinearGradient(
                colors: [Color.brown, Color.brown.opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}
