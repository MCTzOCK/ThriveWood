//
//  BentoIconPickerSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.08.26.
//

import SwiftUI

struct BentoIconPickerSheet: View {
    @Environment(\.bentoTheme) private var theme
    @Binding var selection: String
    let options: [String]
    let tint: Color

    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: theme.spacing.sm) {
                ForEach(options, id: \.self) { name in
                    let isSelected = selection == name
                    Button {
                        Haptics.selection()
                        selection = name
                    } label: {
                        Image(systemName: name)
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: theme.radii.small,
                                    style: .continuous
                                )
                                .fill(
                                    isSelected
                                        ? tint.opacity(0.2)
                                        : theme.colors.surfaceSecondary
                                )
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: theme.radii.small,
                                    style: .continuous
                                )
                                .strokeBorder(
                                    isSelected ? tint : .clear,
                                    lineWidth: theme.borders.regular
                                )
                            }
                            .foregroundStyle(isSelected ? tint : theme.colors.onSurface)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, theme.spacing.value(.md))
            .padding(.bottom, theme.spacing.value(.xl))
        }
        .scrollIndicators(.hidden)
    }
}
