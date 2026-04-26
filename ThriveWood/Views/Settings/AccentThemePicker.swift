//
//  AccentThemePicker.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct AccentThemePicker: View {
    @Binding var selection: AccentTheme

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AccentTheme.allCases) { theme in
                    Button {
                        Haptics.selection()
                        selection = theme
                    } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.color.gradient)
                                    .frame(height: 80)
                                if theme == selection {
                                    Image(systemName: "checkmark")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            Text(theme.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(theme == selection ? theme.color : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Akzentfarbe")
        .navigationBarTitleDisplayMode(.inline)
    }
}
