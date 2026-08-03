//
//  LicenseViewer.swift
//  ThriveWood
//
//  Created by Ben Siebert on 20.05.26.
//


import SwiftUI

public struct OpenSourceLibrary: Identifiable {
    public init(name: String, copyright: String, licenseText: String) {
        self.name = name
        self.copyright = copyright
        self.licenseText = licenseText
    }
    public let id = UUID()
    public let name: String
    public let copyright: String
    public let licenseText: String
}


public struct LicenseViewer: View {
    public let libraries: [OpenSourceLibrary]

    public init(libraries: [OpenSourceLibrary]) {
        self.libraries = libraries
    }

    public var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "books.vertical.fill")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(Color.gray.opacity(0.15))
                        )
                    BentoText(verbatim: "OPEN SOURCE", style: .overline)
                }

                BentoCard(padding: .none, radius: .large) {
                    VStack(spacing: 0) {
                        ForEach(Array(libraries.enumerated()), id: \.element.id) { index, library in
                            NavigationLink(destination: LicenseDetailView(library: library)) {
                                HStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "books.vertical")
                                        .font(Theme.Typography.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                                .fill(Color.accentColor)
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        BentoText(verbatim: library.name, style: .headline)
                                        BentoText(verbatim: library.copyright, style: .caption, color: .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(Theme.Typography.caption.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                                .padding(.horizontal, Theme.Spacing.l)
                                .padding(.vertical, Theme.Spacing.m)
                            }
                            .buttonStyle(.plain)

                            if index < libraries.count - 1 {
                                BentoDivider().padding(.leading, Theme.Spacing.l + 48)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Lizenzen"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseDetailView: View {
    let library: OpenSourceLibrary

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                BentoCard(padding: .lg, radius: .large) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        BentoText(verbatim: library.name, style: .title1)
                        BentoText(verbatim: library.copyright, style: .callout, color: .secondary)
                    }
                }

                BentoCard(padding: .lg, radius: .large) {
                    Text(library.licenseText)
                        .font(Theme.Typography.caption.monospaced())
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle(library.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
