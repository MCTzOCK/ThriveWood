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
    @Environment(\.bentoTheme) private var theme

    struct IconOption: Identifiable, Hashable {
        let id: String               // "default" for primary
        let iconName: String?        // nil = primary, alternate icon name otherwise
        let displayName: String
        let previewName: String
        let isPro: Bool
    }

    private let options: [IconOption] = [
        .init(id: "default", iconName: nil, displayName: "Standard", previewName: "AppIconPreview", isPro: false),
        .init(id: "forest", iconName: "AppIcon-Forest", displayName: "Wald", previewName: "AppIconPreview-Forest", isPro: true),
        .init(id: "night", iconName: "AppIcon-Night", displayName: "Nacht", previewName: "AppIconPreview-Night", isPro: true),
        .init(id: "mono", iconName: "AppIcon-Mono", displayName: "Mono", previewName: "AppIconPreview-Mono", isPro: true),
        .init(id: "cartoon", iconName: "AppIcon-Cartoon", displayName: "Cartoon", previewName: "AppIconPreview-Cartoon", isPro: true)
    ]

    @State private var currentID: String = "default"

    private var currentIconName: String? {
        UIApplication.shared.alternateIconName
    }

    var body: some View {
        BentoBottomSheet(title: Text("App-Symbol"), subtitle: Text("Wähle dein Icon"), showsCloseButton: true) {
            BentoAdaptiveGrid(minimumItemWidth: 140) {
                ForEach(options) { option in
                    iconTile(option)
                }
            }
            .padding(.bottom, Theme.Spacing.l)
        }
        .onAppear {
            currentID = options.first { $0.iconName == currentIconName }?.id ?? "default"
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    // MARK: - Icon Tile

    @ViewBuilder
    private func iconTile(_ option: IconOption) -> some View {
        let isSelected = option.id == currentID

        Button {
            selectIcon(option)
        } label: {
            VStack(spacing: Theme.Spacing.s) {
                ZStack {
                    Image(option.previewName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    isSelected ? theme.colors.success : theme.colors.surface,
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: isSelected ? theme.colors.success.opacity(0.2) : theme.colors.surface, radius: 6, y: 2)

                    if option.isPro {
                        BentoBadge(Text("PRO"), tone: .warning, systemImage: "crown.fill")
                            .offset(x: 28, y: -28)
                    }
                }

                HStack(spacing: Theme.Spacing.xs) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(theme.colors.success)
                    }
                    Text(option.displayName)
                        .font(Theme.Typography.subheadline.weight(isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? theme.colors.success : Color.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
            .padding(.horizontal, Theme.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .fill(isSelected ? theme.colors.success.opacity(0.06) : theme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                            .strokeBorder(
                                isSelected ? theme.colors.success.opacity(0.3) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection

    private func selectIcon(_ option: IconOption) {
        if option.isPro && !env.entitlements.canUseCustomIcons {
            showingPaywall = true
            return
        }

        Haptics.selection()
        currentID = option.id

        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            if error == nil {
                Haptics.success()
            }
        }
    }
}
