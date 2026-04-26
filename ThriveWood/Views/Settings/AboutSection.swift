//
//  AboutSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct AboutSection: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(v) (\(b))"
    }

    var body: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle.fill")
                Spacer()
                Text(version).foregroundStyle(.secondary).monospacedDigit()
            }

            Link(destination: URL(string: "https://mctzock.github.io/ios-apps-pages/legal/privacy")!) {
                Label("Datenschutz", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: "https://mctzock.github.io/ios-apps-pages/legal/notice")!) {
                Label("Impressum", systemImage: "doc.text.fill")
            }
            Link(destination: URL(string: "mailto:hello@ben-siebert.de")!) {
                Label("Feedback senden", systemImage: "envelope.fill")
            }

            ShareLink(
                item: URL(string: "https://apps.apple.com/app/id6763886527")!,
                subject: Text("ThriveWood"),
                message: Text("Lass deinen Wald durch gute Gewohnheiten wachsen 🌱")
            ) {
                Label("App teilen", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("Über")
        } footer: {
            VStack(spacing: 4) {
                Text("Mit ❤️ in Hattingen")
                    .font(.footnote)
                Text("ThriveWood ist 100% deine App – keine Daten verlassen dein Gerät ohne deine Zustimmung.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, Theme.Spacing.l)
        }
    }
}
