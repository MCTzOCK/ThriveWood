//
//  RoutinesView.swift
//  ThriveWood
//
//  Eigener Tab-Screen für Habit-Routinen. Listet alle Routinen als
//  BentoCards, öffnet per Tap den Abarbeiten-Screen, Plus-Button
//  öffnet den Editor.
//

import SwiftUI

@MainActor
@Observable
final class RoutinesViewModel {
    private let env: AppEnvironment

    var routines: [HabitRoutine] = []
    let errors = ErrorState()

    init(env: AppEnvironment) { self.env = env }

    func load() {
        routines = (try? env.routineRepo.fetchAll()) ?? []
    }

    func delete(_ routine: HabitRoutine) {
        do {
            try env.routineRepo.delete(routine)
            withAnimation { routines.removeAll { $0.id == routine.id } }
            Haptics.selection()
        } catch { errors.show(error) }
    }
}

struct RoutinesView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme

    @State private var vm: RoutinesViewModel?
    @State private var showingNew = false
    @State private var editingRoutine: HabitRoutine?
    @State private var presentedRoutine: HabitRoutine?
    @State private var menuRoutine: HabitRoutine?
    @State private var deletingRoutine: HabitRoutine?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
                    .transition(.opacity)
            } else {
                BentoScreen(scrolls: false) {
                    BentoSpinner(size: 36)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .bentoSheet(
            isPresented: $showingNew,
            title: Text("Neue Routine"),
            subtitle: Text("Fasse Habits zu einem Ablauf zusammen"),
            detents: [.large]
        ) {
            RoutineEditorSheet(routine: nil) {
                vm?.load()
            }
        }
        .bentoSheet(
            isPresented: Binding(
                get: { editingRoutine != nil },
                set: { if !$0 { editingRoutine = nil } }
            ),
            title: Text("Routine bearbeiten"),
            detents: [.large]
        ) {
            if let routine = editingRoutine {
                RoutineEditorSheet(routine: routine) {
                    vm?.load()
                }
            }
        }
        .fullScreenCover(item: $presentedRoutine) { routine in
            RoutineRunView(routine: routine) {
                vm?.load()
            }
        }
        .confirmationDialog(
            Text("Routine"),
            isPresented: Binding(
                get: { menuRoutine != nil },
                set: { if !$0 { menuRoutine = nil } }
            ),
            presenting: menuRoutine
        ) { routine in
            Button {
                editingRoutine = routine
                menuRoutine = nil
            } label: {
                Text("Bearbeiten")
            }
            Button(role: .destructive) {
                deletingRoutine = routine
                menuRoutine = nil
            } label: {
                Text("Löschen")
            }
            Button(role: .cancel) {
                menuRoutine = nil
            } label: {
                Text("Abbrechen")
            }
        }
        .confirmationDialog(
            Text("Routine löschen?"),
            isPresented: Binding(
                get: { deletingRoutine != nil },
                set: { if !$0 { deletingRoutine = nil } }
            ),
            presenting: deletingRoutine
        ) { routine in
            Button(role: .destructive) {
                vm?.delete(routine)
                deletingRoutine = nil
            } label: {
                Text("Löschen")
            }
            Button(role: .cancel) {
                deletingRoutine = nil
            } label: {
                Text("Abbrechen")
            }
        } message: { _ in
            Text("Diese Routine wird endgültig entfernt. Die enthaltenen Habits bleiben erhalten.")
        }
        .task {
            if vm == nil { vm = RoutinesViewModel(env: env) }
            vm?.load()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: RoutinesViewModel) -> some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("ABLAUF"),
                title: Text("Routinen"),
                subtitle: Text(vm.routines.isEmpty ? "Noch keine Routinen" : "\(vm.routines.count) Routinen")
            ) {
                BentoIconButton(
                    systemImage: "plus",
                    accessibilityLabel: Text("Neue Routine"),
                    variant: .primary,
                    size: .medium
                ) {
                    showingNew = true
                }
            }

            if vm.routines.isEmpty {
                emptyState
            } else {
                routinesList(vm: vm)
            }

            Spacer(minLength: theme.spacing.xxl)
        }
        .errorAlert(vm.errors)
    }

    // MARK: - Empty

    private var emptyState: some View {
        BentoCard(tone: .accent, style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.colors.onAccent)
                    .symbolEffect(.bounce, value: true)

                VStack(spacing: theme.spacing.xs) {
                    BentoText("Erste Routine erstellen", style: .title3, color: theme.colors.onAccent)
                    BentoText(
                        "Fasse Habits zu einem Ablauf zusammen – z. B. deine Morgenroutine – und arbeite sie mit einem Tipp gemeinsam ab.",
                        style: .body,
                        color: theme.colors.onAccent.opacity(0.85)
                    )
                    .multilineTextAlignment(.center)
                }

                BentoButton(
                    Text("Neue Routine"),
                    systemImage: "plus.circle.fill",
                    variant: .secondary,
                    expands: true
                ) {
                    showingNew = true
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, theme.spacing.xl)
    }

    // MARK: - List

    private func routinesList(vm: RoutinesViewModel) -> some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(vm.routines) { routine in
                routineCard(routine)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        presentedRoutine = routine
                    }
                    .contextMenu {
                        Button {
                            editingRoutine = routine
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deletingRoutine = routine
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private func routineCard(_ routine: HabitRoutine) -> some View {
        BentoCard(tone: .neutral, style: .outlined, padding: .lg, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(routine.color.color.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: routine.iconSystemName)
                        .font(.title3)
                        .foregroundStyle(routine.color.color)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    BentoText(verbatim: routine.title, style: .headline)
                    BentoBadge(
                        Text(verbatim: "\(routine.habitIDs.count) Habits"),
                        tone: .neutral,
                        systemImage: "list.bullet"
                    )
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }
        }
    }
}
