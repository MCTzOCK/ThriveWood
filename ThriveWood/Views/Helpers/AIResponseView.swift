//
//  AIResponseView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.05.26.
//

import SwiftUI
import FoundationModels
import Textual

struct AIResponseView: View {
    
    var initialNavTitle: String
    var navTitle: String
    var prompt: String
    
    @State private var loading = true
    @State private var response = ""
    
    @Environment(AppEnvironment.self) private var env
    
    var body: some View {
        Group {
            if loading {
                ProgressView()
                    .navigationTitle(initialNavTitle)
            } else {
                ScrollView {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.tint)
                            .padding(.trailing, 4)
                            .font(.system(size: 24))
                        Text("Die Antwort der KI könnte unvollständig oder ungenau sein. Bitte überprüfe sie kritisch und verwende sie nur als Anhaltspunkt. Die Antwort ersetzt keine professionelle medizinische Beratung.")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                    .padding(.horizontal, Theme.Spacing.l)
                    
                    StructuredText(
                        markdown: response
                    )
                    .textual.structuredTextStyle(.gitHub)
                    .padding(Theme.Spacing.l)
                }
                .navigationTitle(navTitle)
            }
        }
        .onAppear {
            inference()
        }
    }
    
    private func inference() {
        Task {
            do {
                let stream = env.aiService.stream(for: prompt)
                
                for try await xm in stream {
                    loading = false
                    response = xm.content
                }
            } catch let error {
                response = "Fehler bei der KI-Antwort: \(error.localizedDescription)"
                loading = false
            }
        }
    }
}
