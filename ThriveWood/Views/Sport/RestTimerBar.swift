//
//  RestTimerBar.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct RestTimerBar: View {
    @Bindable var rest: RestTimer

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: rest.progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: rest.progress)
                Image(systemName: "timer").foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pause").font(.caption).foregroundStyle(.white.opacity(0.85))
                Text(rest.formatted)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }
            Spacer()
            Button("+15s") { rest.add(15); Haptics.selection() }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.2)))
                .foregroundStyle(.white)
            Button {
                rest.stop(); Haptics.impact(.light)
            } label: { Image(systemName: "xmark").foregroundStyle(.white) }
                .padding(8)
                .background(Circle().fill(.white.opacity(0.2)))
        }
        .padding(Theme.Spacing.m)
        .background(
            LinearGradient(colors: [.blue, .indigo],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
