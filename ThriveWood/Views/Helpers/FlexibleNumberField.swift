//
//  FlexibleNumberField.swift
//  ThriveWood
//
//  Created by Ben Siebert on 27.05.26.
//

import SwiftUI

struct FlexibleNumberField: View {
    @Binding var value: Double
    let placeholder: String
    let decimal: Bool

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    private let decimalSeparator = Locale.current.decimalSeparator ?? "."

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(decimal ? .decimalPad : .numberPad)
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    commitText()
                }
            }
            .onChange(of: value) { _, newValue in
                if !isFocused {
                    setTextFromValue(newValue)
                }
            }
            .onAppear {
                setTextFromValue(value)
            }
    }

    private func setTextFromValue(_ v: Double) {
        if v == 0 {
            text = ""
        } else if decimal {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            formatter.locale = Locale.current
            text = formatter.string(from: NSNumber(value: v)) ?? formatDefault(v)
        } else {
            text = String(Int(v))
        }
    }

    private func formatDefault(_ v: Double) -> String {
        if decimal {
            let formatted = String(format: "%.2f", v)
            let sep = decimalSeparator
            return formatted.replacingOccurrences(of: ".", with: sep)
        } else {
            return String(Int(v))
        }
    }

    private func commitText() {
        let sanitized = text
            .replacingOccurrences(of: ".", with: decimalSeparator)
            .replacingOccurrences(of: ",", with: decimalSeparator)
            .trimmingCharacters(in: .whitespaces)

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.decimalSeparator = decimalSeparator

        if let parsed = formatter.number(from: sanitized) {
            let doubleVal = parsed.doubleValue
            value = decimal ? doubleVal : Double(Int(doubleVal))
        } else if sanitized.isEmpty {
            value = 0
        } else if let direct = Double(sanitized.replacingOccurrences(of: decimalSeparator, with: ".")) {
            value = decimal ? direct : Double(Int(direct))
        } else {
            setTextFromValue(value)
        }
    }
}
