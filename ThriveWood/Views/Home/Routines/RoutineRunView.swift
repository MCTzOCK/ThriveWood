//
//  RoutineRunView.swift
//  ThriveWood
//
//  "Abarbeiten"-Screen für eine HabitRoutine. Zeigt die geordneten Habits
//  der Routine mit großem Toggle-/Increment-Verhalten und einen
//  Gesamtfortschritt. Schließt sich automatisch, wenn alles erledigt ist.
//

import SwiftUI

@MainActor
@Observable
final class RoutineRunViewModel {
    private let env: AppEnvironment

    var routine: HabitRoutine
    var habits: [Habit] = []
    var completedIDs: Set<UUID> = []
    var progress: [UUID: (value: Double, target: Double, progress: Double)] = [:]
    let errors = ErrorState()
    var didFinish = false

    init(env: AppEnvironment, routine: HabitRoutine) {
        self.env = env
        self.routine = routine
    }

    var totalCount: Int { habits.count }
    var doneCount: Int { completedIDs.count }
    var overallProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }
    var allDone: Bool { !habits.isEmpty && completedIDs.count == habits.count }

    func load() {
        do {
            let all = try env.habitRepo.fetchAll(includeArchived: false)
            habits = routine.habitIDs.compactMap { id in all.first { $0.id == id } }
            refreshStatus()
        } catch { errors.show(error) }
    }

    private func refreshStatus() {
        completedIDs.removeAll()
        progress.removeAll()
        for habit in habits {
            let p = (try? env.habitService.currentProgress(habit)) ?? (value: 0, target: habit.targetValue, progress: 0)
            progress[habit.id] = p
            if p.progress >= 1.0 { completedIDs.insert(habit.id) }
        }
    }

    func toggle(_ habit: Habit) {
        do {
            _ = try env.habitService.toggle(habit)
            refreshStatus()
            checkCompletion()
        } catch { errors.show(error) }
    }

    func increment(_ habit: Habit) {
        do {
            _ = try env.habitService.increment(habit)
            refreshStatus()
            checkCompletion()
        } catch { errors.show(error) }
    }

    func decrement(_ habit: Habit) {
        do {
            _ = try env.habitService.decrement(habit)
            refreshStatus()
        } catch { errors.show(error) }
    }

    func streak(for habit: Habit) -> Int {
        (try? env.habitService.currentStreak(for: habit)) ?? 0
    }

    private func checkCompletion() {
        guard allDone, !didFinish else { return }
        didFinish = true
        Haptics.success()
    }
}

struct RoutineRunView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme

    @State private var vm: RoutineRunViewModel?

    let routine: HabitRoutine
    var onFinished: () -> Void = {}

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
            }
        }
        .task {
            if vm == nil { vm = RoutineRunViewModel(env: env, routine: routine) }
            vm?.load()
        }
        .onChange(of: vm?.didFinish ?? false) { _, finished in
            guard finished else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onFinished()
                dismiss()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: RoutineRunViewModel) -> some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("ROUTINE"),
                title: Text(routine.title),
                subtitle: Text("\(vm.doneCount) von \(vm.totalCount) erledigt")
            ) {
                BentoIconButton(
                    systemImage: "xmark",
                    accessibilityLabel: Text("Schließen"),
                    variant: .secondary
                ) {
                    dismiss()
                }
            }

            progressCard(vm: vm)

            if vm.habits.isEmpty {
                BentoEmptyState(
                    systemImage: "list.bullet.clipboard",
                    title: Text("Keine Habits"),
                    message: Text("Diese Routine enthält keine Habits. Füge welche im Editor hinzu.")
                )
                .padding(.top, theme.spacing.xl)
            } else {
                habitList(vm: vm)
            }

            if vm.allDone {
                doneCard
            }

            Spacer(minLength: theme.spacing.xxl)
        }
        .errorAlert(vm.errors)
    }

    // MARK: - Progress Card

    private func progressCard(vm: RoutineRunViewModel) -> some View {
        BentoCard(tone: .accent, style: .elevated, padding: .lg, radius: .extraLarge) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.lg) {
                    BentoProgressRing(
                        progress: vm.overallProgress,
                        tone: .accent,
                        size: 76,
                        lineWidth: 8,
                        label: Text(verbatim: "\(Int(vm.overallProgress * 100))%")
                    )

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        BentoText(
                            vm.allDone ? "Geschafft!" : "Bleib dran",
                            style: .title3,
                            color: theme.colors.onAccent
                        )
                        HStack(alignment: .lastTextBaseline, spacing: theme.spacing.xxs) {
                            BentoText(
                                verbatim: "\(vm.doneCount)",
                                style: .metric,
                                color: theme.colors.onAccent
                            )
                            BentoText(
                                verbatim: "/ \(vm.totalCount) Habits",
                                style: .callout,
                                color: theme.colors.onAccent.opacity(0.85)
                            )
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Habit List

    private func habitList(vm: RoutineRunViewModel) -> some View {
        VStack(spacing: theme.spacing.md) {
            BentoSectionHeader(title: Text("Habits"), subtitle: Text("\(vm.totalCount) in dieser Routine"))

            BentoAdaptiveGrid(minimumItemWidth: 160) {
                ForEach(vm.habits) { habit in
                    BentoHabitRowView(
                        habit: habit,
                        isCompleted: vm.completedIDs.contains(habit.id),
                        streak: vm.streak(for: habit),
                        progress: vm.progress[habit.id],
                        onToggle: { vm.toggle(habit) },
                        onIncrement: { vm.increment(habit) },
                        onDecrement: { vm.decrement(habit) },
                        onEdit: {}
                    )
                }
            }
        }
    }

    // MARK: - Done Card

    private var doneCard: some View {
        BentoCard(
            background: theme.colors.success.opacity(0.15),
            style: .flat,
            padding: .lg,
            radius: .large
        ) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(theme.colors.success)
                    .symbolEffect(.bounce, value: true)
                BentoText("Routine abgeschlossen!", style: .title3)
                BentoText(
                    "Schließe sich in einem Moment automatisch.",
                    style: .callout,
                    color: theme.colors.onSurfaceMuted
                )
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}
