//
//  ActiveSessionBanner.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI
import Combine

struct ActiveSessionBanner: View {
    let session: WorkoutSession
    let onTap: () -> Void
    
    @State private var now: Date = .now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var elapsed: String {
        let s = Int(now.timeIntervalSince(session.startedAt))
        let m = s / 60, sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(.white.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout läuft").font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(session.workout?.name ?? "Freies Training")
                        .font(.headline).foregroundStyle(.white)
                }
                Spacer()
                Text(elapsed).font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.l)
            .background(
                LinearGradient(colors: [.blue, .indigo],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
            .shadow(color: .blue.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .onReceive(timer) { now = $0 }
    }
}

struct QuickStartCard: View {
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Freies Training").font(.headline).foregroundStyle(.white)
                    Text("Ohne Plan loslegen").font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.8))
            }
            .padding(Theme.Spacing.l)
            .background(
                LinearGradient(colors: [.accentColor, .mint],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }
}

struct WorkoutsSection: View {
    let workouts: [Workout]
    let onStart: (Workout) -> Void
    let onEdit: (Workout) -> Void
    let onDelete: (Workout) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Meine Workouts").font(.headline)
            
            if workouts.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Noch keine Workouts")
                        .font(.subheadline.weight(.semibold))
                    Text("Erstelle deinen ersten Plan über das Plus-Symbol.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .cardStyle()
            } else {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(workouts) { w in
                        WorkoutCard(workout: w, onStart: { onStart(w) }, onEdit: { onEdit(w) })
                            .contextMenu {
                                Button("Bearbeiten", systemImage: "pencil") { onEdit(w) }
                                Button("Archivieren", systemImage: "archivebox", role: .destructive) {
                                    onDelete(w)
                                }
                            }
                    }
                }
            }
        }
    }
}

struct WorkoutCard: View {
    let workout: Workout
    let onStart: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .fill(workout.color.gradient)
                    .frame(width: 54, height: 54)
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name).font(.headline).lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(workout.exercises.count) Übungen", systemImage: "list.bullet")
                    Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: { Haptics.impact(); onEdit() }) {
                    Image(systemName: "gear")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(Color(.tertiarySystemFill)))
                }
                .buttonStyle(.plain)
                Button(action: { Haptics.impact(); onStart() }) {
                    Image(systemName: "play.fill")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(workout.color.color))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}

struct RecentSessionsSection: View {
    let sessions: [WorkoutSession]
    let onSelect: (WorkoutSession) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("Letzte Trainings").font(.headline)
                Spacer()
                if sessions.count > 5 {
                    NavigationLink("Alle") {
                        AllSessionsView(sessions: sessions, onSelect: onSelect)
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            VStack(spacing: Theme.Spacing.s) {
                ForEach(sessions.prefix(5)) { s in
                    Button { onSelect(s) } label: {
                        SessionRow(session: s)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    
    private var duration: String {
        guard let sec = session.durationSeconds else { return "–" }
        return "\(sec / 60) min"
    }
    private var totalVolume: Double {
        session.sets.reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "calendar")
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workout?.name ?? "Freies Training")
                    .font(.subheadline.weight(.semibold))
                Text(session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(duration).font(.subheadline.weight(.semibold))
                Text("\(Int(totalVolume)) kg")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
