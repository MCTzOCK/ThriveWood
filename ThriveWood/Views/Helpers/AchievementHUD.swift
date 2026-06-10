//
//  AchievementHUD.swift
//  ThriveWood
//

import SwiftUI

struct AchievementHUD: ViewModifier {
    @Environment(AppEnvironment.self) private var env
    @State private var displayedNotification: AchievementDefinition?
    @State private var isShowing = false
    @State private var iconScale: CGFloat = 0.3
    @State private var shimmer = false
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let notification = displayedNotification, isShowing {
                    notificationBanner(notification)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .scale(scale: 0.85)).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .scale(scale: 0.9)).combined(with: .opacity)
                        ))
                }
            }
            .onChange(of: env.achievementService.notificationQueue) { _, newValue in
                guard !newValue.isEmpty, displayedNotification == nil else { return }
                showNext()
            }
    }

    private func notificationBanner(_ def: AchievementDefinition) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(def.category.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Circle()
                    .stroke(def.category.color.opacity(0.4), lineWidth: 2)
                    .frame(width: 50, height: 50)

                Image(systemName: def.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(def.category.color)
                    .scaleEffect(iconScale)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Erfolg freigeschaltet!")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(def.category.color)
                Text(def.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, value: isShowing)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [def.category.color.opacity(0.5), def.category.color.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: def.category.color.opacity(0.15), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, 8)
    }

    private func showNext() {
        guard let next = env.achievementService.currentNotification else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            displayedNotification = next
            isShowing = true
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.15)) {
            iconScale = 1.0
        }
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                isShowing = false
                iconScale = 0.3
            }
            try? await Task.sleep(for: .seconds(0.5))
            displayedNotification = nil
            env.achievementService.dismissNotification()
            try? await Task.sleep(for: .seconds(0.3))
            if env.achievementService.currentNotification != nil {
                showNext()
            }
        }
    }
}

extension View {
    func achievementHUD() -> some View {
        modifier(AchievementHUD())
    }
}