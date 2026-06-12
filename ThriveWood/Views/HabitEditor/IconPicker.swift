//
//  IconPicker.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//



import SwiftUI

struct IconPicker: View {
    @Binding var selection: String
    let options: [String]
    let tint: Color
    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options, id: \.self) { name in
                    Button { Haptics.selection(); selection = name } label: {
                        Image(systemName: name)
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .fill(selection == name ? tint.opacity(0.2) : Color.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .strokeBorder(selection == name ? tint : .clear, lineWidth: 2)
                            )
                            .foregroundStyle(selection == name ? tint : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Symbol wählen")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}