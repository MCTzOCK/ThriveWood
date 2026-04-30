//
//  AppIconPickerView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct AppIconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @State private var showingPaywall = false

    struct IconOption: Identifiable, Hashable {
        let id: String?           // nil = primary
        let displayName: String
        let previewName: String   // Bild im Asset-Catalog für die Vorschau
    }

    private let options: [IconOption] = [
        .init(id: nil, displayName: "Standard", previewName: "AppIconPreview"),
        .init(id: "AppIcon-Forest", displayName: "Wald", previewName: "AppIconPreview-Forest"),
        .init(id: "AppIcon-Night",  displayName: "Nacht", previewName: "AppIconPreview-Night"),
        .init(id: "AppIcon-Mono",   displayName: "Mono",  previewName: "AppIconPreview-Mono"),
        .init(id: "AppIcon-Cartoon",   displayName: "Cartoon",  previewName: "AppIconPreview-Cartoon")
    ]

    @State private var current: String? = UIApplication.shared.alternateIconName

    var body: some View {
        NavigationStack {
            List(options) { option in
                Button {
                    if option.id == nil || env.entitlements.canUseCustomIcons {
                        Haptics.selection()
                        setIcon(option.id)
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(option.previewName)
                            .resizable().scaledToFit()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.tertiary))
                            .proBadgeCond(condition: option.id != nil)
                        Text(option.displayName).foregroundStyle(.primary)
                        Spacer()
                        if option.id == current {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("App-Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private func setIcon(_ id: String?) {
        UIApplication.shared.setAlternateIconName(id) { error in
            if error == nil {
                Haptics.success()
                current = id
            }
        }
    }
}
